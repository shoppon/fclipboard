from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class CategoryBase(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    color: str | None = None
    version: int = 1
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class CategoryCreate(CategoryBase):
    id: Optional[UUID] = None


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    color: Optional[str] = None
    version: Optional[int] = None


class CategoryRead(CategoryBase):
    id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
