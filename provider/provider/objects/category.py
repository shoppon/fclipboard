from datetime import datetime
from uuid import uuid4

import attrs

from provider.clients import mongo


@attrs.define
class Category:
    name: str = attrs.Factory(str)
    description: str = attrs.Factory(str)
    icon: str = attrs.Factory(str)
    user: str = attrs.Factory(str)
    uuid: str = attrs.Factory(lambda: str(uuid4()))
    is_private: bool = attrs.Factory(bool)
    created_at: str = attrs.Factory(datetime.utcnow)
    deleted: bool = attrs.Factory(lambda: False)

    def create(self):
        created = mongo.get_collection('category').insert_one(
            attrs.asdict(self)).inserted_id
        return created.binary.hex()

    @staticmethod
    def get_all_by_uid(uid):
        return list(mongo.get_collection('category').find({
            "user": uid
        }))
