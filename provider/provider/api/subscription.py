from fastapi import FastAPI
from loguru import logger
from pydantic import BaseModel
from pydantic.typing import Optional

from provider.objects.entry import Entry as EntryObject
from provider.objects.subscription import Subscription as SubscriptionObject


app = FastAPI()


class Subscription(BaseModel):
    name: str
    description: Optional[str]
    categories: list[str]


class SubscriptionRequest(BaseModel):
    subscription: Subscription


class Parameter(BaseModel):
    name: str
    description: Optional[str]
    initial: Optional[str]
    required: bool


class Entry(BaseModel):
    name: str
    content: str
    category: str
    counter: Optional[int]
    parameters: Optional[list[Parameter]]


class PushRequest(BaseModel):
    entries: list[Entry]


@app.get("/subscriptions")
def get_subscription():
    subscriptions = SubscriptionObject.get_all()
    # convert ObjectId to id field
    for subscription in subscriptions:
        subscription['id'] = subscription.pop('_id').binary.hex()
    return {'subscriptions': subscriptions}


@app.post("/subscriptions")
def create_subscription(request: SubscriptionRequest):
    logger.info(f'Creating subscription, request: {request}.')
    created = SubscriptionObject(**request.subscription.dict()).create()
    logger.info('Creating subscription done.')
    return {'id': created}


@app.post("/subscriptions/{sid}/push")
def push_subscription(sid: str, request: PushRequest):
    logger.info(f'Pushing subscription {sid}, request: {request}.')
    # TODO(xp): batch insert
    for req in request.entries:
        EntryObject(**req.dict()).create()
    logger.info(f'Pushing subscription {sid} done.')
    return {'id': sid}
