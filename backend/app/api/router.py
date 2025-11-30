from fastapi import APIRouter

from . import auth, snippets, tags

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(tags.router, prefix="/tags", tags=["tags"])
api_router.include_router(snippets.router, prefix="/snippets", tags=["snippets"])
