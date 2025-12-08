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
    deleted_at: Optional[datetime] = None


class TagCreate(TagBase):
    id: Optional[UUID] = None


class TagUpdate(BaseModel):
    name: Optional[str] = None
    color: Optional[str] = None
    version: Optional[int] = None
    deleted_at: Optional[datetime] = None


class TagRead(TagBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class TagSyncItem(BaseModel):
    id: Optional[UUID] = None
    name: Optional[str] = None
    color: Optional[str] = None
    version: int = 1
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None


class TagSyncOp(BaseModel):
    op: str = Field(pattern="^(upsert|delete)$")
    tag: TagSyncItem


class TagSyncPayload(BaseModel):
    cursor: Optional[datetime] = None
    ops: list[TagSyncOp] = Field(default_factory=list)


class TagSyncResponse(BaseModel):
    changes: list[TagRead]
    next_cursor: Optional[datetime] = Field(default=None, alias="nextCursor")

    model_config = {"populate_by_name": True}
