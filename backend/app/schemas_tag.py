from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class TagBase(BaseModel):
  name: str = Field(min_length=1, max_length=120)
  color: str | None = None
  version: int = 1
  created_at: Optional[datetime] = None
  updated_at: Optional[datetime] = None


class TagCreate(TagBase):
  id: Optional[UUID] = None


class TagUpdate(BaseModel):
  name: Optional[str] = None
  color: Optional[str] = None
  version: Optional[int] = None


class TagRead(TagBase):
  id: UUID
  created_at: datetime
  updated_at: datetime

  model_config = {"from_attributes": True}
