@description('Azure region')
param location string = resourceGroup().location

@description('Name prefix for resources')
param namePrefix string = 'mead'

@description('Container image (Docker Hub public)')
param containerImage string

@description('Admin username for MySQL Flexible Server')
param dbAdminUser string = 'myadmin'

@secure()
@description('Admin password for MySQL Flexible Server')
param dbAdminPassword string

@description('MySQL database name')
param dbName string = 'contactforms'

@description('Allow ALL IPs to DB (ONLY for short-lived testing)')
param allowAllIps bool = true

@description('Optional: client IP to allow (used only when allowAllIps=false)')
param clientIp string = ''

@description('Container CPU cores')
param containerCpu int = 1

@description('Container memory in Gi')
param containerMemoryGi int = 2

// --- Log Analytics (needed for Container Apps env when using ARM/Bicep) ---
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${namePrefix}-law'
  location: location
  sku: { name: 'PerGB2018' }
  properties: {
    retentionInDays: 7
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

var laCustomerId = law.properties.customerId
var laSharedKey = listKeys(law.id, '2020-08-01').primarySharedKey

// --- MySQL Flexible Server ---
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-01' = {
  name: '${namePrefix}-mysql'
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '8.0.21'
    administratorLogin: dbAdminUser
    administratorLoginPassword: dbAdminPassword
    storage: { storageSizeGB: 20 }
    network: { publicNetworkAccess: 'Enabled' }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: { mode: 'Disabled' }
  }
}

resource mysqlDb 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-01' = {
  name: dbName
  parent: mysqlServer
}

resource fwAll 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-12-01' = if (allowAllIps) {
  name: 'allowAll'
  parent: mysqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource fwClient 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-12-01' = if (!allowAllIps && clientIp != '') {
  name: 'allowClient'
  parent: mysqlServer
  properties: {
    startIpAddress: clientIp
    endIpAddress: clientIp
  }
}

var mysqlFqdn = reference(mysqlServer.id, '2023-12-01').fullyQualifiedDomainName

// --- Container Apps Environment (with Log Analytics) ---
resource caEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${namePrefix}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: laCustomerId
        sharedKey: laSharedKey
      }
    }
  }
}

// --- Container App ---
resource app 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${namePrefix}-app'
  location: location
  properties: {
    managedEnvironmentId: caEnv.id
    configuration: {
      ingress: { external: true, targetPort: 80, transport: 'auto' }
      secrets: [{ name: 'db-pass', value: dbAdminPassword }]
    }
    template: {
      containers: [
        {
          name: 'web'
          image: containerImage
          env: [
            { name: 'DB_HOST', value: mysqlFqdn }
            { name: 'DB_PORT', value: '3306' }
            { name: 'DB_NAME', value: dbName }
            { name: 'DB_USER', value: dbAdminUser }
            { name: 'DB_PASS', secretRef: 'db-pass' }
          ]
          resources: { cpu: containerCpu, memory: '${containerMemoryGi}Gi' }
        }
      ]
      scale: { minReplicas: 0, maxReplicas: 1 }
    }
  }
}

output appFqdn string = app.properties.configuration.ingress.fqdn
output mysqlFqdnOut string = mysqlFqdn
