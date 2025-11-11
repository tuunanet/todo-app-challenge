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

## Running the Azure Function locally (Azure Functions Core Tools)

If you want to run the backend Azure Function locally you need the Azure Functions Core Tools ("func") and a local Python environment. The project repository currently does not contain `host.json` or `local.settings.json` by default, so follow these steps to install the tooling, initialize the project folder, and run the Functions host locally.

Summary (what you'll do):
- Install Node.js and Azure Functions Core Tools (v4)
- (Optional) install Azurite to emulate Azure Storage for local development
- Create and activate a Python virtualenv and install Python deps
- Create `host.json` and `local.settings.json` in `backend/function_app` (or run `func init`)
- Start the Functions host with `func start`

1) Install prerequisites (Linux / Debian/Ubuntu example)

```bash
# install Node.js (needed for func and Azurite)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# install Azure Functions Core Tools v4
sudo npm install -g azure-functions-core-tools@4 --unsafe-perm true

# (optional) install Azurite (local Storage emulator)
sudo npm install -g azurite

# verify installs
func --version
node --version
azurite --version || true
```

If you prefer a distribution-specific package or a package manager (Homebrew, apt repo for Microsoft packages), follow the official install guide for your OS and distribution.

2) Prepare the Python environment and install backend dependencies

```bash
# from repo root
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

3) Prepare the Functions project folder

The Functions host looks for `host.json` in the function app root. If `backend/function_app` does not contain these files, you can initialize the folder using the Core Tools (this will create `host.json`) or create the files manually.

# Option A: let func create the project files (recommended if the folder is empty or not yet initialized)

```bash
cd backend/function_app
func init --worker-runtime python --language python
# create an HTTP-trigger function if you don't have one already (name it TodoFunction to match scaffold)
func new --template "HTTP trigger" --name TodoFunction --authlevel "anonymous"
```

Note: `func init` will not overwrite existing function code files. If your repo already has code under `backend/function_app` (for example a `TodoFunction` subfolder), `func init` will create missing host files and leave your function code intact.

# Option B: create minimal `host.json` and `local.settings.json` manually

Create a minimal `host.json`:

```bash
cat > backend/function_app/host.json <<'JSON'
{
  "version": "2.0"
}
JSON
```

Create `local.settings.json` (DO NOT commit this file - it contains secrets):

```bash
cat > backend/function_app/local.settings.json <<'JSON'
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "COSMOS_MONGO_CONN": "<your-cosmos-mongo-connection-string-here>"
  }
}
JSON
```

If you plan to use Azurite for storage emulation, start it in a separate terminal before starting the Functions host:

```bash
# run Azurite in background (example)
azurite --silent --location /tmp/azurite_db --debug /tmp/azurite_debug.log &
```

4) Start the Functions host

Activate the virtualenv (if not already active) and start the host from the function app folder:

```bash
cd backend
source .venv/bin/activate
cd function_app
func start
```

If everything is configured correctly you should see the functions host start and bind to a localhost port (usually 7071). The HTTP-trigger endpoints will be listed in the host output. Your frontend can call these endpoints via the base URL `http://localhost:7071/api` (adjust Vite env if you use a different base path).

5) Common issues & troubleshooting

- "Unable to find project root. Expecting to find one of host.json, local.settings.json in project root." — Create `host.json` (see step 3) or run `func init` in `backend/function_app`.
- "func: command not found" — Install Azure Functions Core Tools (`npm i -g azure-functions-core-tools@4`), or ensure `func` is in PATH.
- Storage-related errors — Start Azurite or set a real Storage account connection string in `local.settings.json` (`AzureWebJobsStorage`).
- Python worker errors — Make sure your virtualenv is active and `azure-functions` (and other deps) are installed in it. Activate venv before running `func start` so the Functions host uses the same Python environment.

6) Wiring Cosmos DB connection string for local development

- For local development, you can set `COSMOS_MONGO_CONN` in `local.settings.json` to point to a locally running Mongo-compatible instance if you have one, or to a Cosmos DB account in Azure.
- To fetch the Cosmos DB connection string after you deploy the Cosmos account, use the Azure CLI (replace names):

```bash
az cosmosdb keys list --name <cosmosAccountName> --resource-group <rg> --type connection-strings
```

This returns connection strings you can safely copy into `local.settings.json` for testing. When you are ready to update the Function App in Azure, patch the app setting from the CLI instead of writing secrets into repo files:

```bash
az functionapp config appsettings set \
  --name <functionAppName> \
  --resource-group <rg> \
  --settings COSMOS_MONGO_CONN="<primary-connection-string-here>"
```

Security note: never commit `local.settings.json` with production secrets. Add `backend/function_app/local.settings.json` to `.gitignore` if it's not already ignored.

If you'd like, I can also:
- Add a ready-made `host.json` and example `local.settings.json` to the repo (marked as examples, not tracked), or
- Add a Makefile target that will initialize the Functions project and create example local settings (interactive, optional).
Let me know which you prefer and I'll add it.

