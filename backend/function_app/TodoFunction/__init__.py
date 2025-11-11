import os
import sys
import logging

# Ensure the top-level backend package is importable from the function folder
CURRENT_DIR = os.path.dirname(__file__)
REPO_ROOT = os.path.normpath(os.path.join(CURRENT_DIR, '..', '..'))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

import azure.functions as func
from azure.functions import WsgiMiddleware

# Import the Flask app
try:
    from app.main import app
except Exception as e:
    logging.exception("Failed to import Flask app: %s", e)
    raise


def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    """Azure Functions entry point that funnels requests into the Flask WSGI app."""
    return WsgiMiddleware(app).handle(req, context)
