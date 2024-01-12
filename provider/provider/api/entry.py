from loguru import logger

from provider.api import app
from provider.clients.v1.models import Entry
from provider.clients.v1.models import EntryPostReq
from provider.clients.v1.models import EntryPostResp
from provider.objects.entry import Entry as EntryObject


@app.post("/v1/{uid}/entries")
def create_entry(uid: str, request: EntryPostReq):
    logger.info(f'User {uid} creating an entry: {request}.')
    eo = EntryObject(**request.entry.model_dump_json())
    eo.user = uid
    eo.create()
    logger.info(f'User {uid} created an entry.')
    return EntryPostResp(entry=Entry(uuid=eo.uuid,
                                     name=eo.name,
                                     content=eo.content,
                                     category=eo.category,
                                     counter=eo.counter,
                                     user=eo.user,
                                     parameters=eo.parameters,
                                     created_at=eo.created_at,
                                     deleted=eo.deleted))


@app.get("/v1/{uid}/entries")
def list_entry(uid: str):
    logger.info(f'User {uid} listing entries.')
    entries = EntryObject.get_all_by_uid(uid)
    for entry in entries:
        entry.pop('_id')
    logger.info(f'User {uid} listed entries.')
    return {'entries': entries}
