import logging
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from jose import jwt
from sqlalchemy import desc
from sqlalchemy.orm import Session

from .. import models, schemas
from ..config import get_settings

logger = logging.getLogger(__name__)


def _share_expiry() -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=3)


def create_share_token(
    *,
    token_type: str,
    sender_id: str,
    recipient_email: str,
    extra: dict,
) -> schemas.ShareTokenResponse:
    settings = get_settings()
    expires_at = _share_expiry()
    payload = {
        "type": token_type,
        "sender_id": sender_id,
        "recipient_email": recipient_email,
        **{k: str(v) if isinstance(v, UUID) else v for k, v in extra.items()},
        "exp": int(expires_at.timestamp()),
    }
    token = jwt.encode(payload, settings.jwt_secret,
                       algorithm=settings.jwt_algorithm)
    return schemas.ShareTokenResponse(token=token, expiresAt=expires_at)


def decode_share_token(token: str) -> dict:
    settings = get_settings()
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except Exception as exc:  # noqa: BLE001
        raise ValueError("invalid share token") from exc


def resolve_target_tag(
    payload: schemas.SnippetShareRequest,
    sender: models.User,
    recipient: models.User,
    db: Session,
) -> Optional[models.Tag]:
    tag_name = payload.tag_name
    source_tag = None
    if tag_name is None and payload.tag_id:
        source_tag = db.get(models.Tag, payload.tag_id)
        if source_tag is None or str(source_tag.user_id) != str(sender.id):
            return None
        tag_name = source_tag.name

    if tag_name is None:
        return None

    target_tag = (
        db.query(models.Tag)
        .filter(models.Tag.user_id == recipient.id, models.Tag.name == tag_name)
        .order_by(desc(models.Tag.updated_at))
        .first()
    )
    if target_tag:
        return target_tag

    target_tag = models.Tag(
        user_id=recipient.id,
        name=tag_name,
        color=source_tag.color if source_tag else None,
        version=1,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db.add(target_tag)
    db.flush()
    return target_tag


def resolve_shared_tags(
    source_tags: list[models.Tag],
    recipient: models.User,
    db: Session,
) -> list[models.Tag]:
    resolved: list[models.Tag] = []
    seen: set[str] = set()
    for tag in source_tags:
        name = tag.name.strip()
        if not name:
            continue
        key = name.lower()
        if key in seen:
            continue
        existing = (
            db.query(models.Tag)
            .filter(models.Tag.user_id == recipient.id, models.Tag.name == name)
            .order_by(desc(models.Tag.updated_at))
            .first()
        )
        if existing is None:
            existing = models.Tag(
                user_id=recipient.id,
                name=name,
                color=tag.color,
                version=1,
                created_at=datetime.now(timezone.utc),
                updated_at=datetime.now(timezone.utc),
            )
            db.add(existing)
            db.flush()
        resolved.append(existing)
        seen.add(key)
    return resolved


def upsert_shared_snippet(
    source: models.Snippet,
    recipient: models.User,
    target_tag: Optional[models.Tag],
    sender: models.User,
    db: Session,
) -> models.Snippet:
    existing = (
        db.query(models.Snippet)
        .filter(models.Snippet.user_id == recipient.id, models.Snippet.title == source.title)
        .order_by(desc(models.Snippet.updated_at))
        .first()
    )
    shared_from = f"shared from {sender.email}"
    shared_tags = resolve_shared_tags(source.tags, recipient, db)
    if target_tag is not None and target_tag not in shared_tags:
        shared_tags.append(target_tag)
    if existing:
        existing.body = source.body
        existing.tags = shared_tags
        existing.parameters = source.parameters
        existing.source = shared_from
        existing.updated_at = datetime.now(timezone.utc)
        existing.deleted_at = None
        existing.version = (existing.version or 1) + 1
        db.add(existing)
        return existing

    snippet = models.Snippet(
        user_id=recipient.id,
        title=source.title,
        body=source.body,
        source=shared_from,
        pinned=False,
        parameters=source.parameters,
        version=1,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
        deleted_at=None,
        conflict_of=source.id,
    )
    snippet.tags = shared_tags
    db.add(snippet)
    return snippet
