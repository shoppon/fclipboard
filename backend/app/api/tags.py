import logging
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import desc
from sqlalchemy.orm import Session

from .. import models
from ..deps import get_current_user
from ..db import get_db
from ..schemas_tag import TagCreate, TagRead, TagUpdate

router = APIRouter()
logger = logging.getLogger(__name__)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _ensure_aware(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return value if value.tzinfo is not None else value.replace(tzinfo=timezone.utc)


@router.get("", response_model=List[TagRead])
def list_tags(
    updatedAfter: Optional[datetime] = None,
    updatedBefore: Optional[datetime] = None,
    limit: int = 100,
    page: int = 1,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    if page < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="page must be >= 1")
    query = db.query(models.Tag).filter(models.Tag.user_id == user.id)
    if updatedAfter:
        query = query.filter(models.Tag.updated_at > updatedAfter)
    if updatedBefore:
        query = query.filter(models.Tag.updated_at < updatedBefore)
    page_size = max(1, min(limit, 100))
    offset = (page - 1) * page_size
    items = (
        query.order_by(desc(models.Tag.updated_at), desc(models.Tag.id))
        .offset(offset)
        .limit(page_size)
        .all()
    )
    return items


@router.post("", response_model=TagRead, status_code=status.HTTP_201_CREATED)
def create_tag(
    payload: TagCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    try:
        tag = models.Tag(
            id=payload.id,
            user_id=user.id,
            name=payload.name,
            color=payload.color,
            version=payload.version,
            created_at=_ensure_aware(payload.created_at) or _now(),
            updated_at=_ensure_aware(payload.updated_at) or _now(),
        )
        db.add(tag)
        db.commit()
        db.refresh(tag)
        logger.info("tag.create ok user=%s id=%s", user.id, tag.id)
        return tag
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("tag.create failed user=%s payload=%s",
                         user.id, payload.model_dump())
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Create tag failed") from exc


@router.put("/{tag_id}", response_model=TagRead)
def update_tag(
    tag_id: str,
    payload: TagUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    tag = db.get(models.Tag, tag_id)
    if tag is None or str(tag.user_id) != str(user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found")
    try:
        data = payload.model_dump(exclude_unset=True)
        for field, value in data.items():
            setattr(tag, field, value)
        tag.updated_at = _now()
        tag.version = (payload.version or tag.version) + 1
        db.add(tag)
        db.commit()
        db.refresh(tag)
        logger.info("tag.update ok user=%s id=%s version=%s",
                    user.id, tag.id, tag.version)
        return tag
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("tag.update failed user=%s id=%s payload=%s",
                         user.id, tag_id, payload.model_dump())
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Update tag failed") from exc


@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_tag(
    tag_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    tag = db.get(models.Tag, tag_id)
    if tag is None or str(tag.user_id) != str(user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found")
    db.delete(tag)
    db.commit()
    return None


class TagSyncPayload(BaseModel):
    tags: List[TagCreate] = Field(default_factory=list)
    updatedAfter: Optional[datetime] = None


class TagSyncResponse(BaseModel):
    saved: List[TagRead]
    pulled: List[TagRead]


@router.post("/sync", response_model=TagSyncResponse)
def sync_tags(
    payload: TagSyncPayload,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    try:
        saved: List[models.Tag] = []
        for item in payload.tags:
            tag = db.get(models.Tag, item.id) if item.id else None
            incoming_updated = _ensure_aware(item.updated_at) or _now()
            if tag is None:
                tag = models.Tag(
                    id=item.id,
                    user_id=user.id,
                    name=item.name,
                    color=item.color,
                    version=item.version,
                    created_at=_ensure_aware(item.created_at) or _now(),
                    updated_at=incoming_updated,
                )
                db.add(tag)
                db.commit()
                db.refresh(tag)
                saved.append(tag)
                continue

            tag.updated_at = _ensure_aware(tag.updated_at)
            if tag.updated_at and incoming_updated < tag.updated_at:
                continue

            tag.name = item.name or tag.name
            tag.color = item.color or tag.color
            tag.version = max(item.version or tag.version, tag.version + 1)
            tag.updated_at = incoming_updated
            db.add(tag)
            db.commit()
            db.refresh(tag)
            saved.append(tag)

        pull_query = db.query(models.Tag).filter(models.Tag.user_id == user.id)
        if payload.updatedAfter:
            pull_query = pull_query.filter(
                models.Tag.updated_at > payload.updatedAfter)
        if payload.updatedBefore:
            pull_query = pull_query.filter(
                models.Tag.updated_at < payload.updatedBefore)
        pulled_raw = (
            pull_query.order_by(desc(models.Tag.updated_at),
                                desc(models.Tag.id))
            .limit(100)
            .all()
        )
        deduped: dict[str, models.Tag] = {}
        for it in pulled_raw:
            existing = deduped.get(it.name)
            if existing is None or (it.updated_at and existing.updated_at and it.updated_at > existing.updated_at):
                deduped[it.name] = it
        logger.info("tag.sync user=%s pushed=%s pulled=%s",
                    user.id, len(saved), len(deduped))
        return TagSyncResponse(saved=saved, pulled=list(deduped.values()))
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("tag.sync failed user=%s count=%s",
                         user.id, len(payload.tags))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Sync tags failed") from exc
