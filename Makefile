SHELL := /bin/bash

# Simple Makefile to run backend and frontend locally

PYTHON ?= python3
PIP = $(PYTHON) -m pip
VENV_DIR := .venv
ACTIVATE := . $(VENV_DIR)/bin/activate

FRONTEND_DIR := frontend
BACKEND_DIR := backend

.PHONY: help venv install-backend install-frontend run-backend run-backend-func run-frontend clean

help:
	@echo "Makefile targets:"
	@echo "  make venv                # create python virtualenv"
	@echo "  make install-backend     # install backend python deps"
	@echo "  make run-backend         # run Flask backend locally (port 5000)"
	@echo "  make run-backend-func    # run Azure Functions runtime locally (requires 'func' CLI)"
	@echo "  make install-frontend    # install frontend deps (npm)"
	@echo "  make run-frontend        # run frontend dev server (Vite)"
	@echo "  make clean               # remove venv"

venv:
	@echo "Creating virtualenv in $(VENV_DIR)..."
	$(PYTHON) -m venv $(VENV_DIR)
	$(ACTIVATE) && $(PIP) install --upgrade pip setuptools wheel

install-backend: venv
	@echo "Installing backend Python dependencies..."
	$(ACTIVATE) && $(PIP) install -r $(BACKEND_DIR)/requirements.txt

# Run the Flask app directly. Assumes `backend/app/main.py` exposes a Flask `app`.
run-backend: install-backend
	@echo "Running Flask backend on http://0.0.0.0:5000"
	# If backend/.env exists, source it and export variables so COSMOS_MONGO_CONN
	# is available to the Flask process. The .env file should contain lines like
	# COSMOS_MONGO_CONN="mongodb://..."
	$(ACTIVATE) && \
	( if [ -f backend/.env ]; then set -a; . backend/.env; set +a; fi; \
	  FLASK_APP=backend.app.main FLASK_ENV=development FLASK_RUN_HOST=0.0.0.0 FLASK_RUN_PORT=5000 $(PYTHON) -m flask run )

# If you prefer to run the Azure Functions host locally (requires Azure Functions Core Tools):
run-backend-func:
	@echo "Starting Azure Functions host (requires 'func' installed)."
	cd $(BACKEND_DIR) && func start

install-frontend:
	@echo "Installing frontend dependencies..."
	cd $(FRONTEND_DIR) && npm ci

run-frontend: install-frontend
	@echo "Starting frontend dev server (Vite)"
	cd $(FRONTEND_DIR) && npm run dev

clean:
	@echo "Removing virtualenv $(VENV_DIR)"
	rm -rf $(VENV_DIR)
