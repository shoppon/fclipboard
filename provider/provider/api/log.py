from fastapi.responses import Response
from loguru import logger

from provider.api import app
from provider.clients.v1.models import LogPostReq
from provider.objects.log import Log as LogObject


@app.post("/v1/{uid}/logs")
def upload_log(uid: str, request: LogPostReq):
    logger.info(f'User {uid} uploading a log: {request}.')
    lo = LogObject(**request.log.model_dump())
    lo.user = uid
    lo.create()
    logger.info(f'User {uid} uploaded a log.')
    return Response(status_code=204)
