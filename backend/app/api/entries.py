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


@router.get("", response_model=List[schemas.EntryRead])
def list_entries(
    updatedAfter: Optional[datetime] = None,
    limit: int = 100,
    categoryId: Optional[str] = None,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    query = db.query(models.Entry).filter(models.Entry.user_id == user.id)
    if updatedAfter:
        query = query.filter(models.Entry.updated_at > updatedAfter)
    if categoryId:
        try:
            category_uuid = UUID(categoryId)
        except ValueError:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category id")
        query = query.filter(models.Entry.category_id == category_uuid)
    items = query.order_by(desc(models.Entry.updated_at)).limit(min(limit, 500)).all()
    return items


@router.post("", response_model=schemas.EntryRead, status_code=status.HTTP_201_CREATED)
def create_entry(
    payload: schemas.EntryCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    entry = models.Entry(
        id=payload.id,
        user_id=user.id,
        category_id=payload.category_id,
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
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.put("/{entry_id}", response_model=schemas.EntryRead)
def update_entry(
    entry_id: str,
    payload: schemas.EntryUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    entry = db.get(models.Entry, entry_id)
    if entry is None or str(entry.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        if field == "parameters" and value is not None:
            entry.parameters = [param.model_dump() for param in value]
        else:
            setattr(entry, field, value)
    entry.updated_at = datetime.utcnow()
    entry.version = max(payload.version or entry.version, entry.version + 1)
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_entry(
    entry_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    entry = db.get(models.Entry, entry_id)
    if entry is None or str(entry.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")
    entry.deleted_at = datetime.utcnow()
    entry.updated_at = datetime.utcnow()
    entry.version += 1
    db.add(entry)
    db.commit()
    return None


class SyncPayload(BaseModel):
    entries: List[schemas.EntryCreate] = Field(default_factory=list)
    updatedAfter: Optional[datetime] = None


class SyncResponse(BaseModel):
    saved: List[schemas.EntryRead]
    pulled: List[schemas.EntryRead]


@router.post("/sync", response_model=SyncResponse)
def sync_entries(
    payload: SyncPayload,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    saved: List[models.Entry] = []
    for item in payload.entries:
        entry = db.get(models.Entry, item.id) if item.id else None
        incoming_updated = item.updated_at or datetime.utcnow()
        if entry is None:
            entry = models.Entry(
                id=item.id,
                user_id=user.id,
                category_id=item.category_id,
                title=item.title,
                body=item.body,
                tags=item.tags,
                source=item.source,
                pinned=item.pinned,
                version=item.version,
                created_at=item.created_at or datetime.utcnow(),
                updated_at=incoming_updated,
                deleted_at=item.deleted_at,
                conflict_of=item.conflict_of,
            )
            db.add(entry)
            db.commit()
            db.refresh(entry)
            saved.append(entry)
            continue

        # Skip older updates
        if entry.updated_at and incoming_updated < entry.updated_at:
            continue

        entry.title = item.title or entry.title
        entry.body = item.body or entry.body
        entry.tags = item.tags or entry.tags
        entry.source = item.source or entry.source
        entry.pinned = item.pinned if item.pinned is not None else entry.pinned
        entry.category_id = item.category_id or entry.category_id
        entry.parameters = [param.model_dump() for param in item.parameters] or entry.parameters
        entry.deleted_at = item.deleted_at
        entry.conflict_of = item.conflict_of
        entry.version = max(item.version or entry.version, entry.version + 1)
        entry.updated_at = incoming_updated
        db.add(entry)
        db.commit()
        db.refresh(entry)
        saved.append(entry)

    pull_query = db.query(models.Entry).filter(models.Entry.user_id == user.id)
    if payload.updatedAfter:
        pull_query = pull_query.filter(models.Entry.updated_at > payload.updatedAfter)
    pulled = pull_query.order_by(desc(models.Entry.updated_at)).limit(500).all()

    return SyncResponse(saved=saved, pulled=pulled)
