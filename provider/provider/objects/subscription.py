from datetime import datetime

import attrs

from provider.clients import mongo


@attrs.define
class Subscription:

    name: str = attrs.Factory(str)
    url: str = attrs.Factory(str)
    description: str = attrs.Factory(str)
    categories: list = attrs.Factory(list)
    created_at: str = attrs.Factory(datetime.utcnow)

    @staticmethod
    def get(sid):
        return mongo.get_collection('subscription').find_one({'sid': sid})

    @staticmethod
    def get_all():
        return list(mongo.get_collection('subscription').find())

    def create(self):
        created = mongo.get_collection('subscription').insert_one(
            attrs.asdict(self)).inserted_id
        return created.binary.hex()
