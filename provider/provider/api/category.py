from loguru import logger

from provider.api import app
from provider.clients.v1.models import CategoryPostReq
from provider.objects.category import Category as CategoryObject


@app.post("/v1/{uid}/categories")
def create_category(uid: str, request: CategoryPostReq):
    logger.info(f'User {uid} creating a category: {request}.')
    co = CategoryObject(**request.model_dump_json())
    co.user = uid
    co.create()
    logger.info(f'User {uid} created a category.')
