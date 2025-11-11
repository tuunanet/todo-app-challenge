# Azure full-stack app challenge: To-Do list

This repository contains a classic full-stack To-Do Web application made with React.

## Brief Reflection on the project

Which AI tools you used and how:

- I used Github Copilot in VSCode to both generate code and to diagnose and fix various errors

Challenges you encountered and how you solved them:

- Solved deployment and backend errors by discussing with Github Copilot

What you'd improve with more time:

- I would use this To-Do app codebase to refine the specification (generate sequence diagrams and API designs with AI) and then start over from scratch and be more conservative with generative AI usage for the next iteration. I would build more carefully and spend more time planning
- CosmosDB free tier limits turned out to be too strict to be useful, so I would spend more time planning the infrastructure and testing in advance it fulfills the minimum needs for this challenge

## Where to find the screen recording?

I will share a Google drive by email for the final submission.

## Overview

- Backend: Monolithic Azure Function (HTTP trigger) that runs a Flask app. Connects to Azure Cosmos DB (MongoDB API) via a connection string provided with environment variables.
- Frontend: React (hooks) app built for deployment as an Azure Static Web App.
- Data: Cosmos DB (MongoDB API) stores To-Do items (id, title, timestamp, due_date, categories).
- Infra: Azure infrastructure-as-code configuration (Bicep) to provision Resource Group, Cosmos DB (MongoDB API), Function App, Storage Account, and Static Web App. By default most resources are deployed to `northeurope` (North Europe) but the Static Web App is deployed to `westeurope` (West Europe) because that resource is not available in every region. You can override the target location via the Bicep `location` parameter in `infra/bicep/main.bicep`.

Quick dev notes
- Backend expects environment variable `COSMOS_MONGO_CONN` with a MongoDB connection string for Cosmos DB (Mongo API).
- Frontend will call the backend at `/api` by default; set `VITE_API_BASE` for a different base URL.

## Prerequisites (CLI tools)

This project uses several command-line tools for local development, infra validation, and deployment. Before you get started, make sure the following tools are installed and available in your PATH.

Required tools
- Git (for source control)
- Python 3.8+ (for the backend) and pip
- Node.js 18+ and npm (for the frontend and some CLI tools)
- Azure CLI (`az`) — used for account login, resource group and Bicep deployments and retrieving Cosmos connection strings
- Bicep (via Azure CLI: `az bicep`) — used to validate and deploy `infra/bicep/main.bicep`
- Azure Functions Core Tools (`func`) v4 — to run the Functions host locally

Optional but recommended for local emulation
- Azurite — local Azure Storage emulator (useful when running Functions locally without a real Storage account)

Quick verification commands
Run these from a terminal to confirm the basics are installed and available:

```bash
git --version
python3 --version
pip3 --version
node --version
npm --version
az --version
func --version || true        # Optional: shows if func is installed
az bicep version || az bicep install
```

Notes and helpful tips
- Login to Azure before using the Azure CLI: `az login` (and `az account set --subscription <id>` if you have multiple subscriptions).
- If `az bicep version` prints an error, install Bicep with `az bicep install` (the Azure CLI can manage Bicep for you).
- To install Azure Functions Core Tools v4 on Linux you can use npm:

```bash
sudo npm install -g azure-functions-core-tools@4 --unsafe-perm true
````markdown

## Quick start (Makefile)

This repo includes a top-level `Makefile` that helps create a Python virtualenv, install backend deps, and run the frontend dev server.

Common targets

- make install-backend    # creates .venv and installs Python deps
- make run-backend        # runs Flask backend locally (sources backend/.env if present)
- make run-backend-func   # runs the Azure Functions host locally (requires `func`)
- make install-frontend   # run inside frontend to install npm deps
- make run-frontend       # runs Vite dev server
- make venv               # create virtualenv only
- make clean              # remove .venv
- make help               # list Makefile targets

Example

```bash
make install-backend
make run-backend
```

## Local backend (development)

- The backend reads `COSMOS_MONGO_CONN` to connect to Cosmos DB (Mongo API). For local Functions runs, set this in `backend/function_app/local.settings.json` or in `backend/.env` for the Flask dev server.
- A helper script `scripts/fetch-cosmos-conn.sh` can fetch the connection string from Azure and write `backend/.env` (do not commit that file).

Run backend with virtualenv

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
make run-backend
```

Run as Azure Function locally

1. Ensure `func` is installed and your virtualenv deps are available.
2. Create `backend/function_app/host.json` and `local.settings.json` (or run `func init` / `func new` to create scaffolding).
3. Start the host from `backend/function_app`:

```bash
cd backend
source .venv/bin/activate
cd function_app
func start
```

Your functions will normally listen on `http://localhost:7071` and the frontend can call them at `/api` (adjust `VITE_API_BASE` if you change the path).

## Infra (Bicep)

The template `infra/bicep/main.bicep` is resource-group scoped. Typical deploy flow:

1. Create a resource group (defaults to `northeurope` in the template):

```bash
az group create --name rg-todoapp-dev --location northeurope
```

2. Validate and deploy the Bicep template:

```bash
az deployment group validate \
  --resource-group rg-todoapp-dev \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/parameters.json

az deployment group create \
  --resource-group rg-todoapp-dev \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/parameters.json
```

Notes
- Resource names such as a Cosmos account or Storage account must be globally unique — change defaults in `infra/bicep/parameters.json` if needed.
- The Static Web App resource is placed in `westeurope` in the template because it's not available in every region; edit the template if you prefer another region.
- You may see informational Bicep warnings (BCP081) when using preview API versions; these do not always block deployments.

After deploy
- Retrieve the Cosmos DB connection string with the Azure CLI and set it in your Function App app settings (do not store production secrets in source control):

```bash
az cosmosdb keys list --name <cosmosAccountName> --resource-group <rg> --type connection-strings

az functionapp config appsettings set \
  --name <functionAppName> \
  --resource-group <rg> \
  --settings COSMOS_MONGO_CONN="<primary-connection-string>"
```

## Security and secrets

- Never commit `local.settings.json`, `.env`, or other files that contain production secrets. Use `.gitignore` to exclude `backend/.env` and `backend/function_app/local.settings.json`.
- For CI/CD and production, store secrets in the platform's secret store (Azure App Settings, Key Vault, GitHub Secrets, etc.).

## Project layout

- `backend/` — Azure Function + Flask app
- `frontend/` — React + Vite app
- `infra/bicep/` — Bicep templates and parameters
- `scripts/` — helper scripts (e.g., fetch Cosmos connection string)

