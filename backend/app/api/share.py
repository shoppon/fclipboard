import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import models, schemas
from ..deps import get_current_user
from ..db import get_db
from ..services.share_service import (
    decode_share_token,
    resolve_target_tag,
    upsert_shared_snippet,
)

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/accept", response_model=schemas.ShareAcceptResponse)
def accept_share(
    payload: schemas.ShareAcceptRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    try:
        data = decode_share_token(payload.token)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid share token"
        )

    recipient_email = data.get("recipient_email")
    if not recipient_email or recipient_email.lower() != user.email.lower():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Share token not for this user"
        )

    token_type = data.get("type")
    sender_id = data.get("sender_id")
    if not token_type or not sender_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid share token payload"
        )

    sender_user = db.get(models.User, sender_id)
    if sender_user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Sender not found"
        )

    if token_type == "share_snippet":
        snippet_id = data.get("snippet_id")
        if not snippet_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Missing snippet id"
            )
        snippet = db.get(models.Snippet, snippet_id)
        if snippet is None or str(snippet.user_id) != str(sender_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Snippet not found"
            )
        target_tag = resolve_target_tag(
            schemas.SnippetShareRequest(
                email=recipient_email,
                tag_id=data.get("tag_id"),
                tag_name=data.get("tag_name"),
            ),
            sender_user,
            user,
            db,
        )
        saved = upsert_shared_snippet(
            snippet, user, target_tag, sender_user, db)
        db.commit()
        logger.info("share.accept snippet sender=%s recipient=%s snippet=%s",
                    sender_id, user.id, snippet.id)
        return schemas.ShareAcceptResponse(imported=1, tag_id=saved.tag_id)

    if token_type == "share_tag":
        tag_id = data.get("tag_id")
        if not tag_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Missing tag id"
            )
        tag = db.get(models.Tag, tag_id)
        if tag is None or str(tag.user_id) != str(sender_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found"
            )
        share_payload = schemas.SnippetShareRequest(
            email=recipient_email,
            tag_id=tag.id,
            tag_name=data.get("tag_name") or tag.name,
        )
        target_tag = resolve_target_tag(share_payload, sender_user, user, db)
        snippets = (
            db.query(models.Snippet)
            .filter(
                models.Snippet.user_id == sender_user.id,
                models.Snippet.deleted_at.is_(None),
                models.Snippet.tag_id == tag.id,
            )
            .all()
        )
        imported = 0
        for sn in snippets:
            upsert_shared_snippet(sn, user, target_tag, sender_user, db)
            imported += 1
        db.commit()
        logger.info("share.accept tag sender=%s recipient=%s tag=%s imported=%s",
                    sender_id, user.id, tag.id, imported)
        return schemas.ShareAcceptResponse(
            imported=imported, tag_id=target_tag.id if target_tag else None
        )

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported share token type"
    )
