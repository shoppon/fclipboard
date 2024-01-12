from loguru import logger

from provider.api import app
from provider.clients.v1.models import Category
from provider.clients.v1.models import CategoryListResp
from provider.clients.v1.models import CategoryPostReq
from provider.clients.v1.models import CategoryPostResp
from provider.objects.category import Category as CategoryObject


@app.post("/v1/{uid}/categories")
def create_category(uid: str, request: CategoryPostReq):
    logger.info(f'User {uid} creating a category: {request}.')
    co = CategoryObject(**request.category.model_dump())
    co.user = uid
    co.create()
    logger.info(f'User {uid} created a category.')
    return CategoryPostResp(
        category=Category(
            name=co.name,
            icon=co.icon,
            uuid=co.uuid,
            is_private=co.is_private,
            deleted=co.deleted,
        )
    )


@app.get("/v1/{uid}/categories")
def list_category(uid: str):
    logger.info(f'User {uid} listing categories.')
    categories = CategoryObject.get_all_by_uid(uid)
    logger.info(f'User {uid} listed categories.')
    return CategoryListResp(
        categories=[Category(**item)
                    for item in categories])
