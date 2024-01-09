from loguru import logger
from pydantic import BaseModel
from typing import Optional

from provider.api import app
from provider.objects.entry import Entry as EntryObject


class Parameter(BaseModel):
    name: str
    description: Optional[str]
    initial: Optional[str]
    required: Optional[bool]


class Entry(BaseModel):
    name: str
    content: str
    category: str
    counter: Optional[int]
    parameters: Optional[list[Parameter]]


@app.post("/v1/{uid}/entries")
def create_entry(uid: str, request: Entry):
    logger.info(f'User {uid} creating an entry: {request}.')
    eo = EntryObject(**request.dict())
    eo.user = uid
    eo.create()
    logger.info(f'User {uid} created an entry.')
