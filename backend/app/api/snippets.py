import logging
from datetime import datetime, timezone
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import desc
from sqlalchemy.orm import Session

from .. import models, schemas
from ..deps import get_current_user
from ..db import get_db
from ..services.share_service import (
    create_share_token,
)

router = APIRouter()
logger = logging.getLogger(__name__)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _ensure_aware(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return value if value.tzinfo is not None else value.replace(tzinfo=timezone.utc)


def _safe_tag_id(db: Session, user_id: UUID, tag_id: UUID | None) -> UUID | None:
    if tag_id is None:
        return None
    tag = db.get(models.Tag, tag_id)
    if tag is None or str(tag.user_id) != str(user_id):
        return None
    return tag_id


@router.get("", response_model=List[schemas.SnippetRead])
def list_snippets(
    updatedAfter: Optional[datetime] = None,
    updatedBefore: Optional[datetime] = None,
    limit: int = 100,
    page: int = 1,
    tagId: Optional[str] = None,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    if page < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="page must be >= 1")
    query = db.query(models.Snippet).filter(
        models.Snippet.user_id == user.id, models.Snippet.deleted_at.is_(None)
    )
    if updatedAfter:
        query = query.filter(models.Snippet.updated_at > updatedAfter)
    if updatedBefore:
        query = query.filter(models.Snippet.updated_at < updatedBefore)
    if tagId:
        try:
            tag_uuid = UUID(tagId)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid tag id")
        query = query.filter(models.Snippet.tag_id == tag_uuid)
    page_size = max(1, min(limit, 100))
    offset = (page - 1) * page_size
    items = (
        query.order_by(desc(models.Snippet.updated_at),
                       desc(models.Snippet.id))
        .offset(offset)
        .limit(page_size)
        .all()
    )
    return items


@router.get("/full", response_model=List[schemas.SnippetRead])
def download_all_snippets(
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
        db.query(models.Snippet)
        .filter(models.Snippet.user_id == user.id)
        .order_by(desc(models.Snippet.updated_at), desc(models.Snippet.id))
        .offset(offset)
        .limit(page_size)
        .all()
    )


@router.post("", response_model=schemas.SnippetRead, status_code=status.HTTP_201_CREATED)
def create_snippet(
    payload: schemas.SnippetCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    try:
        snippet = models.Snippet(
            id=payload.id,
            user_id=user.id,
            tag_id=payload.tag_id,
            title=payload.title,
            body=payload.body,
            tags=payload.tags,
            source=payload.source,
            pinned=payload.pinned,
            version=payload.version,
            parameters=[param.model_dump() for param in payload.parameters],
            created_at=_ensure_aware(payload.created_at) or _now(),
            updated_at=_ensure_aware(payload.updated_at) or _now(),
            deleted_at=payload.deleted_at,
            conflict_of=payload.conflict_of,
        )
        db.add(snippet)
        db.commit()
        db.refresh(snippet)
        logger.info("snippet.create ok user=%s id=%s", user.id, snippet.id)
        return snippet
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("snippet.create failed user=%s payload=%s",
                         user.id, payload.model_dump())
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Create snippet failed") from exc


@router.put("/{snippet_id}", response_model=schemas.SnippetRead)
def update_snippet(
    snippet_id: str,
    payload: schemas.SnippetUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    snippet = db.get(models.Snippet, snippet_id)
    if snippet is None or str(snippet.user_id) != str(user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Snippet not found")
    try:
        for field, value in payload.model_dump(exclude_unset=True).items():
            if field == "parameters" and value is not None:
                snippet.parameters = [param.model_dump() for param in value]
            else:
                setattr(snippet, field, value)
        snippet.updated_at = _now()
        snippet.version = max(
            payload.version or snippet.version, snippet.version + 1)
        db.add(snippet)
        db.commit()
        db.refresh(snippet)
        logger.info("snippet.update ok user=%s id=%s version=%s",
                    user.id, snippet.id, snippet.version)
        return snippet
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("snippet.update failed user=%s id=%s payload=%s",
                         user.id, snippet_id, payload.model_dump())
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Update snippet failed") from exc


@router.delete("/{snippet_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_snippet(
    snippet_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    snippet = db.get(models.Snippet, snippet_id)
    if snippet is None or str(snippet.user_id) != str(user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Snippet not found")
    snippet.deleted_at = _now()
    snippet.updated_at = _now()
    snippet.version += 1
    db.add(snippet)
    db.commit()
    return None


@router.post("/{snippet_id}/share", response_model=schemas.ShareTokenResponse)
def share_snippet(
    snippet_id: str,
    payload: schemas.SnippetShareRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    snippet = db.get(models.Snippet, snippet_id)
    if snippet is None or str(snippet.user_id) != str(user.id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Snippet not found")
    if snippet.deleted_at is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Snippet is deleted")
    recipient = (
        db.query(models.User)
        .filter(models.User.email == payload.email)
        .first()
    )
    if recipient is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Recipient not found")

    return create_share_token(
        token_type="share_snippet",
        sender_id=str(user.id),
        recipient_email=recipient.email,
        extra={
            "snippet_id": snippet.id,
            "tag_id": payload.tag_id,
            "tag_name": payload.tag_name,
        },
    )


class SyncOp(BaseModel):
    op: str = Field(pattern="^(upsert|delete)$")
    snippet: schemas.SnippetCreate


class SyncPayload(BaseModel):
    cursor: Optional[datetime] = None
    ops: List[SyncOp] = Field(default_factory=list)


class SyncResponse(BaseModel):
    changes: List[schemas.SnippetRead]
    next_cursor: Optional[datetime] = Field(default=None, alias="nextCursor")

    model_config = {"populate_by_name": True}


@router.post("/sync", response_model=SyncResponse)
def sync_snippets(
    payload: SyncPayload,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    try:
        cursor = _ensure_aware(payload.cursor)
        applied = 0
        for op in payload.ops:
            item = op.snippet
            incoming_updated = _ensure_aware(item.updated_at) or _now()
            snippet = db.get(models.Snippet, item.id) if item.id else None
            if snippet is None:
                if op.op == "delete":
                    continue
                snippet = models.Snippet(
                    id=item.id,
                    user_id=user.id,
                    tag_id=_safe_tag_id(db, user.id, item.tag_id),
                    title=item.title,
                    body=item.body,
                    tags=item.tags,
                    source=item.source,
                    pinned=item.pinned,
                    version=item.version,
                    parameters=[param.model_dump()
                                for param in item.parameters],
                    created_at=_ensure_aware(
                        item.created_at) or incoming_updated,
                    updated_at=incoming_updated,
                    deleted_at=_ensure_aware(item.deleted_at),
                    conflict_of=item.conflict_of,
                )
                db.add(snippet)
                db.commit()
                db.refresh(snippet)
                applied += 1
                continue

            if str(snippet.user_id) != str(user.id):
                continue

            current_ts = snippet.deleted_at or snippet.updated_at
            if current_ts and incoming_updated < current_ts:
                continue

            snippet.title = item.title or snippet.title
            snippet.body = item.body or snippet.body
            snippet.tags = item.tags or snippet.tags
            snippet.source = item.source or snippet.source
            snippet.pinned = item.pinned if item.pinned is not None else snippet.pinned
            snippet.tag_id = _safe_tag_id(
                db, user.id, item.tag_id) or snippet.tag_id
            snippet.conflict_of = item.conflict_of
            snippet.parameters = [param.model_dump()
                                  for param in item.parameters] or snippet.parameters
            if op.op == "delete":
                snippet.deleted_at = _ensure_aware(
                    item.deleted_at) or incoming_updated
            else:
                snippet.deleted_at = _ensure_aware(
                    item.deleted_at) or snippet.deleted_at
            snippet.version = max(
                item.version or snippet.version, snippet.version + 1)
            snippet.updated_at = incoming_updated
            db.add(snippet)
            db.commit()
            db.refresh(snippet)
            applied += 1

        pull_query = db.query(models.Snippet).filter(
            models.Snippet.user_id == user.id
        )
        if cursor:
            pull_query = pull_query.filter(
                (models.Snippet.updated_at > cursor)
                | (models.Snippet.deleted_at > cursor)
            )
        pulled = (
            pull_query.order_by(
                desc(models.Snippet.updated_at), desc(models.Snippet.id))
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
        logger.info("snippet.sync user=%s applied=%s changes=%s cursor=%s",
                    user.id, applied, len(pulled), next_cursor)
        return SyncResponse(changes=pulled, nextCursor=next_cursor)
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("snippet.sync failed user=%s count=%s",
                         user.id, len(payload.ops))
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail="Sync snippets failed") from exc
