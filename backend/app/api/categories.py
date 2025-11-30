from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import desc
from sqlalchemy.orm import Session

from .. import models
from ..deps import get_current_user
from ..db import get_db
from ..schemas_category import CategoryCreate, CategoryRead, CategoryUpdate

router = APIRouter()


@router.get("", response_model=List[CategoryRead])
def list_categories(
    updatedAfter: Optional[datetime] = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    query = db.query(models.Category).filter(models.Category.user_id == user.id)
    if updatedAfter:
        query = query.filter(models.Category.updated_at > updatedAfter)
    items = query.order_by(desc(models.Category.updated_at)).limit(min(limit, 500)).all()
    return items


@router.post("", response_model=CategoryRead, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    category = models.Category(
        id=payload.id,
        user_id=user.id,
        name=payload.name,
        color=payload.color,
        version=payload.version,
        created_at=payload.created_at or datetime.utcnow(),
        updated_at=payload.updated_at or datetime.utcnow(),
    )
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.put("/{category_id}", response_model=CategoryRead)
def update_category(
    category_id: str,
    payload: CategoryUpdate,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    category = db.get(models.Category, category_id)
    if category is None or str(category.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(category, field, value)
    category.updated_at = datetime.utcnow()
    category.version = (payload.version or category.version) + 1
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: str,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    category = db.get(models.Category, category_id)
    if category is None or str(category.user_id) != str(user.id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    db.delete(category)
    db.commit()
    return None


class CategorySyncPayload(BaseModel):
    categories: List[CategoryCreate] = Field(default_factory=list)
    updatedAfter: Optional[datetime] = None


class CategorySyncResponse(BaseModel):
    saved: List[CategoryRead]
    pulled: List[CategoryRead]


@router.post("/sync", response_model=CategorySyncResponse)
def sync_categories(
    payload: CategorySyncPayload,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    saved: List[models.Category] = []
    for item in payload.categories:
        cat = db.get(models.Category, item.id) if item.id else None
        incoming_updated = item.updated_at or datetime.utcnow()
        if cat is None:
            cat = models.Category(
                id=item.id,
                user_id=user.id,
                name=item.name,
                color=item.color,
                version=item.version,
                created_at=item.created_at or datetime.utcnow(),
                updated_at=incoming_updated,
            )
            db.add(cat)
            db.commit()
            db.refresh(cat)
            saved.append(cat)
            continue

        if cat.updated_at and incoming_updated < cat.updated_at:
            continue

        cat.name = item.name or cat.name
        cat.color = item.color or cat.color
        cat.version = max(item.version or cat.version, cat.version + 1)
        cat.updated_at = incoming_updated
        db.add(cat)
        db.commit()
        db.refresh(cat)
        saved.append(cat)

    pull_query = db.query(models.Category).filter(models.Category.user_id == user.id)
    if payload.updatedAfter:
        pull_query = pull_query.filter(models.Category.updated_at > payload.updatedAfter)
    pulled = pull_query.order_by(desc(models.Category.updated_at)).limit(500).all()

    return CategorySyncResponse(saved=saved, pulled=pulled)
