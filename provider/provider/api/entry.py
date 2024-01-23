from fastapi.responses import Response
from loguru import logger

from provider.api import app
from provider.clients.v1.models import Entry
from provider.clients.v1.models import EntryPatchReq
from provider.clients.v1.models import EntryPatchResp
from provider.clients.v1.models import EntryPostReq
from provider.clients.v1.models import EntryPostResp
from provider.objects.entry import Entry as EntryObject


@app.post("/v1/{uid}/entries")
def create_entry(uid: str, request: EntryPostReq):
    logger.info(f'User {uid} creating an entry: {request}.')
    eo = EntryObject.get_by_name(uid, request.entry.name)
    if not eo:
        eo = EntryObject(**request.entry.model_dump())
        eo.user = uid
        eo.create()
        logger.info(f'User {uid} created an entry.')
    return EntryPostResp(entry=Entry(uuid=eo.uuid,
                                     name=eo.name,
                                     content=eo.content,
                                     category=eo.category,
                                     counter=eo.counter,
                                     version=eo.version,
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


@app.delete("/v1/{uid}/entries/{eid}")
def delete_entry(uid: str, eid: str):
    logger.info(f'User {uid} deleting an entry {eid}.')
    eo = EntryObject.get(uid, eid)
    if not eo:
        return Response(status_code=404)

    eo.delete()
    logger.info(f'User {uid} deleted an entry {eid}.')
    # return 204
    return Response(status_code=204)


@app.patch("/v1/{uid}/entries/{eid}")
def update_entry(uid: str, eid: str, request: EntryPatchReq):
    logger.info(f'User {uid} updating an entry {eid}.')
    eo = EntryObject.get(uid, eid)
    if not eo:
        return Response(status_code=404)

    # check version, not allow to update an entry with old version
    if request.entry.version != eo.version:
        return Response(status_code=409)

    # increment version
    request.entry.version += 1

    updated = eo.update(request.entry)
    logger.info(f'User {uid} updated an entry {eid}.')
    return EntryPatchResp(entry=Entry(uuid=updated.uuid,
                                      name=updated.name,
                                      content=updated.content,
                                      category=updated.category,
                                      counter=updated.counter,
                                      version=updated.version,
                                      user=updated.user,
                                      parameters=updated.parameters,
                                      created_at=updated.created_at,
                                      deleted=updated.deleted))
