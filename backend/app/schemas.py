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
    tag_ids: List[UUID] = Field(default_factory=list)
    source: Optional[str] = None
    pinned: bool = False
    version: int = 1
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
    tag_ids: Optional[List[UUID]] = None
    source: Optional[str] = None
    pinned: Optional[bool] = None
    version: Optional[int] = None
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


class SnippetShareRequest(BaseModel):
    email: EmailStr
    tag_id: Optional[UUID] = Field(default=None, alias="tagId")
    tag_name: Optional[str] = Field(
        default=None, alias="tagName", max_length=120)

    model_config = {"populate_by_name": True}


class TagShareRequest(BaseModel):
    email: EmailStr
    tag_id: Optional[UUID] = Field(default=None, alias="tagId")
    tag_name: Optional[str] = Field(
        default=None, alias="tagName", max_length=120)

    model_config = {"populate_by_name": True}


class ShareTokenResponse(BaseModel):
    token: str
    expires_at: datetime = Field(alias="expiresAt")


class ShareAcceptRequest(BaseModel):
    token: str


class ShareAcceptResponse(BaseModel):
    imported: int
    tag_id: Optional[UUID] = Field(default=None, alias="tagId")
