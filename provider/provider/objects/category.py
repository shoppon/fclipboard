from datetime import datetime

import attrs

from provider.clients import mongo


@attrs.define
class Category:
    name: str = attrs.Factory(str)
    icon: str = attrs.Factory(str)
    user: str = attrs.Factory(str)
    is_private: bool = attrs.Factory(bool)
    created_at: str = attrs.Factory(datetime.utcnow)

    def create(self):
        created = mongo.get_collection('category').insert_one(
            attrs.asdict(self)).inserted_id
        return created.binary.hex()
