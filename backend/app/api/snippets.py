import logging
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import desc
from sqlalchemy.orm import Session

from .. import models, schemas
from ..deps import get_current_user
from ..db import get_db

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("", response_model=List[schemas.SnippetRead])
def list_snippets(
    updatedAfter: Optional[datetime] = None,
    limit: int = 100,
    tagId: Optional[str] = None,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    query = db.query(models.Snippet).filter(models.Snippet.user_id == user.id)
    if updatedAfter:
        query = query.filter(models.Snippet.updated_at > updatedAfter)
    if tagId:
        try:
            tag_uuid = UUID(tagId)
        except ValueError:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid tag id")
        query = query.filter(models.Snippet.tag_id == tag_uuid)
    items = query.order_by(desc(models.Snippet.updated_at)).limit(min(limit, 500)).all()
    return items


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
            created_at=payload.created_at or datetime.utcnow(),
            updated_at=payload.updated_at or datetime.utcnow(),
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
        logger.exception("snippet.create failed user=%s payload=%s", user.id, payload.model_dump())
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Create snippet failed") from exc


@router.put("/{snippet_id}", response_model=schemas.SnippetRead)
def update_snippet(
    snippet_id: str,
    payload: schemas.SnippetUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    snippet = db.get(models.Snippet, snippet_id)
    if snippet is None or str(snippet.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Snippet not found")
    try:
        for field, value in payload.model_dump(exclude_unset=True).items():
            if field == "parameters" and value is not None:
                snippet.parameters = [param.model_dump() for param in value]
            else:
                setattr(snippet, field, value)
        snippet.updated_at = datetime.utcnow()
        snippet.version = max(payload.version or snippet.version, snippet.version + 1)
        db.add(snippet)
        db.commit()
        db.refresh(snippet)
        logger.info("snippet.update ok user=%s id=%s version=%s", user.id, snippet.id, snippet.version)
        return snippet
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("snippet.update failed user=%s id=%s payload=%s", user.id, snippet_id, payload.model_dump())
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Update snippet failed") from exc


@router.delete("/{snippet_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_snippet(
    snippet_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    snippet = db.get(models.Snippet, snippet_id)
    if snippet is None or str(snippet.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Snippet not found")
    snippet.deleted_at = datetime.utcnow()
    snippet.updated_at = datetime.utcnow()
    snippet.version += 1
    db.add(snippet)
    db.commit()
    return None


class SyncPayload(BaseModel):
    snippets: List[schemas.SnippetCreate] = Field(default_factory=list)
    updatedAfter: Optional[datetime] = None


class SyncResponse(BaseModel):
    saved: List[schemas.SnippetRead]
    pulled: List[schemas.SnippetRead]


@router.post("/sync", response_model=SyncResponse)
def sync_snippets(
    payload: SyncPayload,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    try:
        saved: List[models.Snippet] = []
        for item in payload.snippets:
            snippet = db.get(models.Snippet, item.id) if item.id else None
            incoming_updated = item.updated_at or datetime.utcnow()
            if snippet is None:
                snippet = models.Snippet(
                    id=item.id,
                    user_id=user.id,
                    tag_id=item.tag_id,
                    title=item.title,
                    body=item.body,
                    tags=item.tags,
                    source=item.source,
                    pinned=item.pinned,
                    version=item.version,
                    parameters=[param.model_dump() for param in item.parameters],
                    created_at=item.created_at or datetime.utcnow(),
                    updated_at=incoming_updated,
                    deleted_at=item.deleted_at,
                    conflict_of=item.conflict_of,
                )
                db.add(snippet)
                db.commit()
                db.refresh(snippet)
                saved.append(snippet)
                continue

            if snippet.updated_at and incoming_updated < snippet.updated_at:
                continue

            snippet.title = item.title or snippet.title
            snippet.body = item.body or snippet.body
            snippet.tags = item.tags or snippet.tags
            snippet.source = item.source or snippet.source
            snippet.pinned = item.pinned if item.pinned is not None else snippet.pinned
            snippet.tag_id = item.tag_id or snippet.tag_id
            snippet.deleted_at = item.deleted_at
            snippet.conflict_of = item.conflict_of
            snippet.parameters = [param.model_dump() for param in item.parameters] or snippet.parameters
            snippet.version = max(item.version or snippet.version, snippet.version + 1)
            snippet.updated_at = incoming_updated
            db.add(snippet)
            db.commit()
            db.refresh(snippet)
            saved.append(snippet)

        pull_query = db.query(models.Snippet).filter(models.Snippet.user_id == user.id)
        if payload.updatedAfter:
            pull_query = pull_query.filter(models.Snippet.updated_at > payload.updatedAfter)
        pulled = pull_query.order_by(desc(models.Snippet.updated_at)).limit(500).all()
        logger.info("snippet.sync user=%s pushed=%s pulled=%s", user.id, len(saved), len(pulled))
        return SyncResponse(saved=saved, pulled=pulled)
    except Exception as exc:  # noqa: BLE001
        db.rollback()
        logger.exception("snippet.sync failed user=%s count=%s", user.id, len(payload.snippets))
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Sync snippets failed") from exc
