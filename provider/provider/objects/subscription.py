from datetime import datetime

import attrs

from provider.clients import mongo


@attrs.define
class Subscription:

    name: str = attrs.Factory(str)
    url: str = attrs.Factory(str)
    description: str = attrs.Factory(str)
    categories: list = attrs.Factory(list)
    users: list = attrs.Factory(list)
    public: bool = attrs.Factory(bool)
    created_at: str = attrs.Factory(datetime.utcnow)
    create_by: str = attrs.Factory(str)

    @staticmethod
    def get(sid):
        return mongo.get_collection('subscription').find_one({'sid': sid})

    @staticmethod
    def get_all(uid=None):
        if uid is not None:
            _filter = {
                "$or": [{
                    "users": {
                        "$elemMatch": {
                            "$eq": uid
                        }
                    },
                }, {
                    "public": True,
                }]
            }
        else:
            _filter = {}
        return list(mongo.get_collection('subscription').find(_filter))

    def create(self):
        created = mongo.get_collection('subscription').insert_one(
            attrs.asdict(self)).inserted_id
        return created.binary.hex()
