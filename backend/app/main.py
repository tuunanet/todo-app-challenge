from flask import Flask, request, jsonify
from datetime import datetime
import os
import time
import random
from .repository import TodoRepository

app = Flask(__name__)

# Repo configured via env var COSMOS_MONGO_CONN
MONGO_CONN = os.environ.get('COSMOS_MONGO_CONN', 'mongodb://localhost:27017')
repo = TodoRepository(MONGO_CONN)


def _generate_id():
    # integer id based on timestamp + small random to reduce collisions
    return int(time.time() * 1000) + random.randint(0, 999)


@app.route('/api/todos', methods=['GET'])
def list_todos():
    items = repo.list_todos()
    return jsonify(items), 200


@app.route('/api/todos', methods=['POST'])
def create_todo():
    data = request.get_json() or {}
    title = data.get('title', '').strip()
    if not title:
        return jsonify({'error': 'title is required'}), 400

    item = {
        'id': _generate_id(),
        'title': title,
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'due_date': data.get('due_date'),
        'categories': data.get('categories', [])
    }
    repo.create_todo(item)
    return jsonify(item), 201


@app.route('/api/todos/<int:item_id>', methods=['DELETE'])
def delete_todo(item_id):
    deleted = repo.delete_todo(item_id)
    if deleted:
        return jsonify({'deleted': item_id}), 200
    return jsonify({'error': 'not found'}), 404


@app.route('/api/todos/<int:item_id>', methods=['PUT'])
def update_todo(item_id):
    data = request.get_json() or {}
    updated = repo.update_todo(item_id, data)
    if updated:
        return jsonify(updated), 200
    return jsonify({'error': 'not found'}), 404


# Dummy Entra ID endpoints (placeholders to implement auth later)
@app.route('/api/auth/login', methods=['POST'])
def auth_login():
    return jsonify({'message': 'login endpoint placeholder'}), 200


@app.route('/api/auth/callback', methods=['GET'])
def auth_callback():
    return jsonify({'message': 'callback endpoint placeholder'}), 200


# Ownership endpoints (dummy implementation)
@app.route('/api/todos/<int:item_id>/ownership', methods=['POST'])
def edit_ownership(item_id):
    # placeholder - accept payload but do not enforce auth
    payload = request.get_json() or {}
    return jsonify({'message': 'ownership updated (dummy)', 'item_id': item_id, 'payload': payload}), 200


@app.route('/api/todos/<int:item_id>/ownership', methods=['DELETE'])
def delete_ownership(item_id):
    # placeholder - accept request but do not enforce auth
    return jsonify({'message': 'ownership removed (dummy)', 'item_id': item_id}), 200


# Simple health
@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'}), 200
