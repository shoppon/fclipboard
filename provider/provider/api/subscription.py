from fastapi import FastAPI
from loguru import logger
from pydantic import BaseModel
from pydantic.typing import Optional

from provider.clients import mongo
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


@app.get("/v1/{uid}/subscriptions")
def get_subscription(uid: str):
    subscriptions = SubscriptionObject.get_all(uid)
    # convert ObjectId to id field
    for subscription in subscriptions:
        subscription['id'] = subscription.pop('_id').binary.hex()
    return {'subscriptions': subscriptions}


@app.post("/v1/{uid}/subscriptions")
def create_subscription(uid: str, request: SubscriptionRequest):
    logger.info(f'Creating subscription, request: {request}.')
    subscription = SubscriptionObject(**request.subscription.dict())
    subscription.create_by = uid
    subscription.users.append(uid)
    created = subscription.create()
    logger.info('Creating subscription done.')
    return {'id': created}


@app.post("/v1/{udi}/subscriptions/{sid}/push")
def push_subscription(uid: str, sid: str, request: PushRequest):
    logger.info(f'Pushing subscription {sid}, request: {request}.')
    ops = []
    for req in request.entries:
        eb = EntryObject(**req.dict())
        eb.subscriptions = list(set(eb.subscriptions + [sid]))
        ops.append(eb.build())
    mongo.batch_insert(mongo.get_collection('entry'), ops)
    logger.info(f'Pushing subscription {sid} done.')
    return {'id': sid}


@app.get("/v1/{uid}/subscriptions/{sid}/pull")
def pull_subscription(uid: str, sid: str):
    logger.info(f'Pulling subscription {sid}.')
    entries = EntryObject.get_all(sid)
    for entry in entries:
        entry['id'] = entry.pop('_id').binary.hex()
    logger.info(f'Pulling subscription {sid} done.')
    return {'entries': entries}


@app.get("/v1/oauth/callback")
def oauth_callback():
    return {}
