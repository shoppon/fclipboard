from pymongo.mongo_client import MongoClient


def get_collection(name):
    mc = MongoClient('mongodb://root:mongo@localhost:32717/')
    return mc['fclipboard'][name]
