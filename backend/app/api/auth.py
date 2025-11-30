import logging
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .. import models, schemas
from ..config import get_settings
from ..db import get_db
from ..deps import get_current_user
from ..security import create_access_token, create_refresh_token, get_password_hash, verify_password


router = APIRouter()
settings = get_settings()
logger = logging.getLogger(__name__)


@router.post("/register", response_model=schemas.Token, status_code=status.HTTP_201_CREATED)
def register(payload: schemas.UserCreate, db: Session = Depends(get_db)) -> schemas.Token:
    existing = db.query(models.User).filter(models.User.email == payload.email).first()
    if existing:
        logger.info("Register failed: email already registered %s", payload.email)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    if len(payload.password.encode("utf-8")) > 72:
        logger.info("Register failed: password too long for %s", payload.email)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Password too long (max 72 bytes for bcrypt)")
    try:
        user = models.User(
            email=payload.email,
            password_hash=get_password_hash(payload.password),
            role="user",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        logger.info("Register failed: integrity error (duplicate?) for %s", payload.email)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    jti = uuid4().hex
    refresh_expires = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    refresh_record = models.RefreshToken(jti=jti, user_id=user.id, expires_at=refresh_expires, revoked=False)
    db.add(refresh_record)
    db.commit()

    access = create_access_token(subject=str(user.id))
    refresh = create_refresh_token(subject=str(user.id), jti=jti)
    return schemas.Token(access_token=access, refresh_token=refresh)


@router.post("/login", response_model=schemas.Token)
def login(payload: schemas.UserCreate, db: Session = Depends(get_db)) -> schemas.Token:
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if user is None or not verify_password(payload.password, user.password_hash):
        logger.info("Login failed: bad credentials for %s", payload.email)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User disabled")
    if len(payload.password.encode("utf-8")) > 72:
        logger.info("Login failed: password too long for %s", payload.email)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Password too long (max 72 bytes for bcrypt)")

    jti = uuid4().hex
    refresh_expires = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    refresh_record = models.RefreshToken(jti=jti, user_id=user.id, expires_at=refresh_expires, revoked=False)
    db.add(refresh_record)
    db.commit()

    access = create_access_token(subject=str(user.id))
    refresh = create_refresh_token(subject=str(user.id), jti=jti)
    return schemas.Token(access_token=access, refresh_token=refresh)


class RefreshRequest(BaseModel):
    refresh_token: str


@router.post("/refresh", response_model=schemas.Token)
def refresh_token(request: RefreshRequest, db: Session = Depends(get_db)) -> schemas.Token:
    from jose import JWTError, jwt

    try:
        payload = jwt.decode(request.refresh_token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

    jti = payload.get("jti")
    user_id = payload.get("sub")
    if not jti or not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Malformed token")

    record = db.query(models.RefreshToken).filter(models.RefreshToken.jti == jti).first()
    if record is None or record.revoked:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token revoked")
    if record.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired")

    access = create_access_token(subject=str(user_id))
    refresh = create_refresh_token(subject=str(user_id), jti=jti)
    return schemas.Token(access_token=access, refresh_token=refresh)


@router.get("/me", response_model=schemas.UserRead)
def me(user=Depends(get_current_user)):
    return user
