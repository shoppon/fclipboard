from pymongo.mongo_client import MongoClient

from provider.config import settings


def get_collection(name):
    mc = MongoClient(settings.mongo_url, connecttimeoutms=3000)
    return mc['fclipboard'][name]


def batch_insert(collection, ops):
    collection.bulk_write(ops)
