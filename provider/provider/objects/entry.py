from datetime import datetime

import attrs
from pymongo import UpdateOne

from provider.clients import mongo


@attrs.define
class Param:
    name: str = attrs.Factory(str)
    description: str = attrs.Factory(str)
    initial: str = attrs.Factory(str)
    required: bool = attrs.Factory(bool)


@attrs.define
class Entry:
    name: str = attrs.Factory(str)
    content: str = attrs.Factory(str)
    category: str = attrs.Factory(str)
    counter: int = attrs.Factory(int)
    user: str = attrs.Factory(str)
    parameters: list[Param] = attrs.Factory(list)
    created_at: str = attrs.Factory(datetime.utcnow)
    subscriptions: list[str] = attrs.Factory(list)

    def get(self, sid):
        return mongo.get_collection('entry').find_one({'sid': sid})

    @staticmethod
    def get_all(sid):
        return list(mongo.get_collection('entry').find({
            "subscriptions": {
                "$elemMatch": {
                    "$eq": sid
                }
            }
        }))

    def build(self):
        update_op = UpdateOne(
            {
                'name': self.name
            }, {
                '$set': attrs.asdict(self),
            },
            upsert=True
        )
        return update_op

    def create(self):
        created = mongo.get_collection('entry').insert_one(
            attrs.asdict(self)).inserted_id
        return created.binary.hex()
