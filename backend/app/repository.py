from pymongo import MongoClient
from pymongo.errors import ServerSelectionTimeoutError
from typing import List, Dict, Any

class TodoRepository:
    def __init__(self, mongo_conn: str, db_name: str = 'todo_db', collection: str = 'todos'):
        self.mongo_conn = mongo_conn
        self.db_name = db_name
        self.collection_name = collection
        self.client = MongoClient(mongo_conn, serverSelectionTimeoutMS=5000)
        try:
            # trigger server selection to catch connection issues early
            self.client.server_info()
        except ServerSelectionTimeoutError:
            # In dev, allow absence of Mongo; operations may fail later.
            pass
        self.db = self.client[self.db_name]
        self.col = self.db[self.collection_name]

    def list_todos(self) -> List[Dict[str, Any]]:
        docs = list(self.col.find({}, {'_id': 0}).sort('timestamp', -1))
        return docs

    def create_todo(self, item: Dict[str, Any]):
        # store by id field
        self.col.insert_one(item)
        return item

    def delete_todo(self, item_id: int) -> bool:
        res = self.col.delete_one({'id': item_id})
        return res.deleted_count == 1

    def update_todo(self, item_id: int, data: Dict[str, Any]):
        update_fields = {}
        for k in ('title', 'due_date', 'categories'):
            if k in data:
                update_fields[k] = data[k]
        if not update_fields:
            return None
        res = self.col.find_one_and_update({'id': item_id}, {'$set': update_fields}, projection={'_id':0}, return_document=True)
        return res
