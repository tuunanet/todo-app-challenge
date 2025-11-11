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
