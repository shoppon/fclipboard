import logging
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import desc
from sqlalchemy.orm import Session

from .. import models, schemas
from ..deps import get_current_user
from ..db import get_db
from ..schemas_tag import (
    TagCreate,
    TagRead,
    TagSyncPayload,
    TagSyncResponse,
    TagUpdate,
)
from ..services.share_service import create_share_token

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
    query = (
        db.query(models.Tag)
        .filter(models.Tag.user_id == user.id, models.Tag.deleted_at.is_(None))
    )
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


@router.get("/full", response_model=List[TagRead])
def download_all_tags(
    limit: int = 200,
    page: int = 1,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    if page < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="page must be >= 1")
    page_size = max(1, min(limit, 500))
    offset = (page - 1) * page_size
    return (
        db.query(models.Tag)
        .filter(models.Tag.user_id == user.id)
        .order_by(desc(models.Tag.updated_at), desc(models.Tag.id))
        .offset(offset)
        .limit(page_size)
        .all()
    )


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
            deleted_at=_ensure_aware(payload.deleted_at),
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
    tag.deleted_at = _now()
    tag.updated_at = tag.deleted_at
    tag.version += 1
    db.add(tag)
    db.commit()
    return None


@router.post("/{tag_id}/share", response_model=schemas.ShareTokenResponse)
def share_tag(
    tag_id: str,
    payload: schemas.TagShareRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    tag = db.get(models.Tag, tag_id)
    if tag is None or str(tag.user_id) != str(user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found")
    if tag.deleted_at is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Tag is deleted")

    recipient = (
        db.query(models.User)
        .filter(models.User.email == payload.email)
        .first()
    )
    if recipient is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Recipient not found")

    token = create_share_token(
        token_type="share_tag",
        sender_id=str(user.id),
        recipient_email=recipient.email,
        extra={
            "tag_id": tag.id,
            "tag_name": payload.tag_name or tag.name,
        },
    )
    logger.info("tag.share token created sender=%s recipient=%s tag=%s",
                user.id, recipient.id, tag.id)
    return token


@router.post("/sync", response_model=TagSyncResponse)
def sync_tags(
    payload: TagSyncPayload,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    try:
        cursor = _ensure_aware(payload.cursor)
        applied = 0
        for op in payload.ops:
            item = op.tag
            incoming_updated = _ensure_aware(item.updated_at) or _now()
            tag = db.get(models.Tag, item.id) if item.id else None
            if tag is None:
                if op.op == "delete":
                    continue
                if not item.name:
                    continue
                tag = models.Tag(
                    id=item.id,
                    user_id=user.id,
                    name=item.name,
                    color=item.color,
                    version=item.version,
                    created_at=_ensure_aware(
                        item.created_at) or incoming_updated,
                    updated_at=incoming_updated,
                    deleted_at=_ensure_aware(item.deleted_at),
                )
                db.add(tag)
                db.commit()
                db.refresh(tag)
                applied += 1
                continue

            if str(tag.user_id) != str(user.id):
                continue

            current_ts = tag.deleted_at or tag.updated_at
            if current_ts and incoming_updated < current_ts:
                continue

            if op.op == "delete":
                tag.deleted_at = _ensure_aware(
                    item.deleted_at) or incoming_updated
            else:
                if item.name:
                    tag.name = item.name
                tag.color = item.color or tag.color
                tag.deleted_at = _ensure_aware(
                    item.deleted_at) or tag.deleted_at
            tag.version = max(item.version or tag.version, tag.version + 1)
            tag.updated_at = incoming_updated
            db.add(tag)
            db.commit()
            db.refresh(tag)
            applied += 1

        pull_query = db.query(models.Tag).filter(models.Tag.user_id == user.id)
        if cursor:
            pull_query = pull_query.filter(
                (models.Tag.updated_at > cursor)
                | (models.Tag.deleted_at > cursor)
            )
        pulled = (
            pull_query.order_by(desc(models.Tag.updated_at),
                                desc(models.Tag.id))
            .limit(200)
            .all()
        )
        next_cursor: datetime | None = cursor
        for it in pulled:
            ts = it.deleted_at or it.updated_at
            if ts is None:
                continue
            if next_cursor is None or ts > next_cursor:
                next_cursor = ts
        if next_cursor is None:
            next_cursor = _now()
        logger.info(
            "tag.sync user=%s applied=%s changes=%s cursor=%s",
            user.id,
            applied,
            len(pulled),
            next_cursor,
        )
        return TagSyncResponse(changes=pulled, nextCursor=next_cursor)
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("tag.sync failed user=%s ops=%s",
                         user.id, len(payload.ops))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Sync tags failed") from exc
