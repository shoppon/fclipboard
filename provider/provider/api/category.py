from typing import Optional

from loguru import logger
from pydantic import BaseModel

from provider.api import app
from provider.objects.category import Category as CategoryObject


class Category(BaseModel):
    name: str
    icon: str
    is_private: Optional[bool]


@app.post("/v1/{uid}/categories")
def create_category(uid: str, request: Category):
    logger.info(f'User {uid} creating a category: {request}.')
    co = CategoryObject(**request.dict())
    co.user = uid
    co.create()
    logger.info(f'User {uid} created a category.')
