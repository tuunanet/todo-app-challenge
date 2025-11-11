@description('Location to deploy resources')
param location string = 'northeurope'

@description('Location display name for primary region')
param locationName string = 'North Europe'

@description('Cosmos DB account name (must be globally unique)')
param cosmosAccountName string = 'todocosmosacct'

@description('Mongo database name')
param mongoDbName string = 'todo-db'

@description('Mongo collection name')
param mongoCollectionName string = 'todos'

// derive a storage account name from resource group and location to help uniqueness
var storageAccountName = toLower(uniqueString(resourceGroup().id, location, 'sa'))

@description('App Service plan name')
param appServicePlanName string = 'todo-asp'

@description('Function App name')
param functionAppName string = 'todo-mymega-function-app'

@description('Static Web App name')
param staticSiteName string = 'todo-static-site'

@description('Cosmos DB tagging: default experience label')
param defaultExperience string = 'Azure Cosmos DB for MongoDB API'


@description('Paired location display name')
param pairedLocationName string = location

// Cosmos DB account (MongoDB API)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-05-01-preview' = {
  name: cosmosAccountName
  location: location
  kind: 'MongoDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    // locations: primary and paired
    locations: [
      {
        failoverPriority: 0
        locationName: locationName
      }
      {
        failoverPriority: 1
        locationName: pairedLocationName
      }
    ]
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Geo'
      }
    }
    isVirtualNetworkFilterEnabled: false
    virtualNetworkRules: []
    ipRules: []
    minimalTlsVersion: 'Tls12'
    enableMultipleWriteLocations: false
    capabilities: [
      {
        name: 'EnableMongo'
      }
    ]
    apiProperties: {
      serverVersion: '7.0'
    }
    capacityMode: 'Provisioned'
    enableFreeTier: true
    capacity: {
      totalThroughputLimit: 1000
    }
  }
  tags: {
    defaultExperience: defaultExperience
    'hidden-workload-type': 'Learning'
    'hidden-cosmos-mmspecial': ''
  }

  // child resources: MongoDB database and collection
  resource mongoDatabase 'mongodbDatabases@2025-05-01-preview' = {
    name: mongoDbName
    properties: {
      resource: {
        id: mongoDbName
      }
      options: {}
    }

    resource mongoCollection 'collections@2025-05-01-preview' = {
      name: mongoCollectionName
      properties: {
        resource: {
          id: mongoCollectionName
        }
        options: {
          throughput: 400
        }
      }
    }
  }
}



// Storage account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

// App Service plan for Function App (Consumption/Dynamic)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

// Function App (Linux, Python)
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'COSMOS_MONGO_CONN'
          value: 'REPLACE_WITH_COSMOS_MONGO_CONNECTION_STRING'
        }
      ]
    }
  }
}

// Static Web App (minimal placeholder - recommend connecting via GitHub Actions or Azure Static Web Apps CI)
resource staticSite 'Microsoft.Web/staticSites@2022-03-01' = {
  name: staticSiteName
  // Static Sites currently not available in all regions; deploy to West Europe where supported
  location: 'westeurope'
  sku: {
    name: 'Free'
  }
  properties: {
    repositoryToken: ''
  }
}

// Outputs
output cosmosAccountEndpoint string = cosmosAccount.properties.documentEndpoint
output storageAccountName string = storageAccount.name
output functionAppName string = functionApp.name
output staticSiteName string = staticSite.name
