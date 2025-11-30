from fastapi import APIRouter

from . import auth, categories, entries

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])
api_router.include_router(entries.router, prefix="/entries", tags=["entries"])
