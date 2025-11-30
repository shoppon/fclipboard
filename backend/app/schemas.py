from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    sub: str
    exp: int
    jti: str | None = None


class UserBase(BaseModel):
    email: EmailStr


class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=72)


class UserRead(UserBase):
    id: UUID
    role: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class Parameter(BaseModel):
    name: str = ""
    description: Optional[str] = None
    initial: Optional[str] = None
    required: bool = False


class SnippetBase(BaseModel):
    title: str
    body: str = ""
    tags: List[str] = Field(default_factory=list)
    source: Optional[str] = None
    pinned: bool = False
    version: int = 1
    tag_id: Optional[UUID] = None
    parameters: List[Parameter] = Field(default_factory=list)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None
    conflict_of: Optional[UUID] = None


class SnippetCreate(SnippetBase):
    id: Optional[UUID] = None


class SnippetUpdate(BaseModel):
    title: Optional[str] = None
    body: Optional[str] = None
    tags: Optional[List[str]] = None
    source: Optional[str] = None
    pinned: Optional[bool] = None
    version: Optional[int] = None
    tag_id: Optional[UUID] = None
    parameters: Optional[List[Parameter]] = None
    deleted_at: Optional[datetime] = None
    conflict_of: Optional[UUID] = None


class SnippetRead(SnippetBase):
    id: UUID
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None
    conflict_of: Optional[UUID] = None

    model_config = {"from_attributes": True}
