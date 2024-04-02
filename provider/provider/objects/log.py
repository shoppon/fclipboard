from datetime import datetime

import attrs

from provider.clients import mongo


@attrs.define
class Log:
    action: str = attrs.Factory(str)
    content: str = attrs.Factory(str)
    stack: str = attrs.Factory(str)
    platform: str = attrs.Factory(str)
    user: str = attrs.Factory(str)
    created_at: str = attrs.Factory(datetime.now)

    def create(self):
        created = mongo.get_collection('log').insert_one(
            attrs.asdict(self)).inserted_id
        return created.binary.hex()
