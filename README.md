# To-Do Challenge — Fullstack Azure App

This repository contains a scaffold for a classic To-Do web application.

Overview
- Backend: Monolithic Azure Function (HTTP trigger) that runs a Flask app. Connects to Azure Cosmos DB (MongoDB API) via a connection string provided with environment variables.
- Frontend: React (hooks) app built for deployment as an Azure Static Web App.
- Data: Cosmos DB (MongoDB API) stores To-Do items (id, title, timestamp, due_date, categories).
- Infra: Terraform configuration to provision Resource Group, Cosmos DB (MongoDB API), Function App, Storage Account, and Static Web App in `northeurope` (Europe North) using free-tier where applicable.

Quick dev notes
- Backend expects environment variable `COSMOS_MONGO_CONN` with a MongoDB connection string for Cosmos DB (Mongo API).
- Frontend will call the backend at `/api` by default; set `VITE_API_BASE` for a different base URL.

Contents
- `backend/` — Azure Function + Flask app scaffold
- `frontend/` — React app scaffold (Vite)
- `infra/` — Terraform configuration for Azure resources

Next steps
1. Install backend dependencies (see `backend/requirements.txt`).
2. Run frontend locally with `npm install` and `npm run dev` inside `frontend/`.
3. Configure `COSMOS_MONGO_CONN` to connect to a Cosmos DB for MongoDB and start the backend.

This scaffold focuses on clarity and extendability. Implementations are intentionally simple and designed to be replaced/extended when you connect real cloud credentials and CI/CD.

## Bicep (ARM) deployment

This repository includes a Bicep conversion of the Terraform infra under `infra/bicep/`.

Notes before you deploy:
- You need the Azure CLI installed and be logged in (`az login`).
- The Cosmos DB account and Storage account names must be globally unique; change defaults in `infra/bicep/parameters.json` before deploying.

Warnings you may see during validation:
- Bicep may emit BCP081 warnings like "resource type ... does not have types available" for some preview or newer API versions (this is informational and occurs when the local Bicep type metadata doesn't include that API schema). These warnings do not necessarily block deployment.

If you want to suppress or avoid BCP081 warnings you can either:
- Use stable API versions that the local Bicep registry contains, or
- Split the template into modules and/or update the Bicep type registry (not required for successful deployment).


- The Bicep template in `infra/bicep/main.bicep` is resource-group scoped. Create the resource group first, then deploy the template into that resource group (recommended).

Example deploy steps (resource-group scope):

1. Create the resource group (if you don't have one already):

```bash
az group create --name rg-todoapp-dev --location northeurope
```

2. Validate and deploy the Bicep template into the resource group:

```bash
# from repo root
az deployment group validate \
  --resource-group rg-todoapp-dev \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/parameters.json

az deployment group create \
  --resource-group rg-todoapp-dev \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/parameters.json
```

3. After deployment the CLI prints outputs. The Bicep template attempts to output the Cosmos endpoint and a primary connection string (the latter may require permissions and the correct API version to access).

Notes on post-deploy wiring:
- Update your Function App `COSMOS_MONGO_CONN` app setting with the Cosmos DB Mongo connection string (you can retrieve it in the portal or via `az cosmosdb keys list` / `az cosmosdb connection-strings list` commands).
- Deploy your Function App code (zip deploy, git Action, or Azure Functions deployment) and your static web app assets (via GitHub Actions or Azure Static Web Apps deployment).

If you'd like I can also:
- Add a small `az cli` script to fetch the Cosmos DB Mongo connection string and patch the Function App app settings automatically.
- Add a GitHub Actions workflow to build and deploy the frontend to the Static Web App and the Function App.

