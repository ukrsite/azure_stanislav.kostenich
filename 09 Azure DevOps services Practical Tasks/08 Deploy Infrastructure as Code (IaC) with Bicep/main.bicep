// Define parameters
param location string = resourceGroup().location
param appServicePlanName string = 'MySampleAppPlan'
param webAppName string = 'devWebApp2025'
param sqlServerName string = 'MySampleSqlServer2025'
param sqlDatabaseName string = 'MySampleDatabase'
param sqlAdminUsername string = 'sqladmin'
param sqlAdminPassword string

// Create an App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

// Create a Web App
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'SQL_CONNECTION_STRING'
          value: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
      ]
    }
  }
}

// Create a SQL Server
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
  }
}

// Create a SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}
