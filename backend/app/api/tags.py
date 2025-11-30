from datetime import datetime
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


@router.get("", response_model=List[TagRead])
def list_tags(
    updatedAfter: Optional[datetime] = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    query = db.query(models.Tag).filter(models.Tag.user_id == user.id)
    if updatedAfter:
        query = query.filter(models.Tag.updated_at > updatedAfter)
    items = query.order_by(desc(models.Tag.updated_at)).limit(min(limit, 500)).all()
    return items


@router.post("", response_model=TagRead, status_code=status.HTTP_201_CREATED)
def create_tag(
    payload: TagCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    tag = models.Tag(
        id=payload.id,
        user_id=user.id,
        name=payload.name,
        color=payload.color,
        version=payload.version,
        created_at=payload.created_at or datetime.utcnow(),
        updated_at=payload.updated_at or datetime.utcnow(),
    )
    db.add(tag)
    db.commit()
    db.refresh(tag)
    return tag


@router.put("/{tag_id}", response_model=TagRead)
def update_tag(
    tag_id: str,
    payload: TagUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    tag = db.get(models.Tag, tag_id)
    if tag is None or str(tag.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found")
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(tag, field, value)
    tag.updated_at = datetime.utcnow()
    tag.version = (payload.version or tag.version) + 1
    db.add(tag)
    db.commit()
    db.refresh(tag)
    return tag


@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_tag(
    tag_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    tag = db.get(models.Tag, tag_id)
    if tag is None or str(tag.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found")
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
    saved: List[models.Tag] = []
    for item in payload.tags:
        tag = db.get(models.Tag, item.id) if item.id else None
        incoming_updated = item.updated_at or datetime.utcnow()
        if tag is None:
            tag = models.Tag(
                id=item.id,
                user_id=user.id,
                name=item.name,
                color=item.color,
                version=item.version,
                created_at=item.created_at or datetime.utcnow(),
                updated_at=incoming_updated,
            )
            db.add(tag)
            db.commit()
            db.refresh(tag)
            saved.append(tag)
            continue

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
        pull_query = pull_query.filter(models.Tag.updated_at > payload.updatedAfter)
    pulled = pull_query.order_by(desc(models.Tag.updated_at)).limit(500).all()

    return TagSyncResponse(saved=saved, pulled=pulled)
