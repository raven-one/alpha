@description('Azure region')
param location string = resourceGroup().location
@description('Name prefix for resources')
param namePrefix string = 'mead'
@description('Container image (Docker Hub or ACR)')
param containerImage string
@description('Admin username for MySQL Flexible Server')
param dbAdminUser string = 'myadmin'
@secure()
@description('Admin password for MySQL Flexible Server (also used by app for simplicity)')
param dbAdminPassword string
@description('MySQL database name')
param dbName string = 'contactforms'
@description('Allow ALL IPs to DB (ONLY for short-lived testing)')
param allowAllIps bool = false
@description('Optional: client IP to allow (e.g., your laptop public IP)')
param clientIp string = ''
@description('Container CPU cores')
param containerCpu int = 1
@description('Container memory in Gi')
param containerMemoryGi int = 2
resource mysql 'Microsoft.DBforMySQL/flexibleServers@2023-12-01' = {name: '${namePrefix}-mysql' location: location sku: {name: 'Standard_B1ms' tier: 'Burstable' capacity: 1 size: 'B1ms' family: 'B'} properties: {version: '8.0.21' administratorLogin: dbAdminUser administratorLoginPassword: dbAdminPassword storage: {storageSizeGB: 20 iops: 360} network: {publicNetworkAccess: 'Enabled'} backup: {backupRetentionDays: 7 geoRedundantBackup: 'Disabled'} highAvailability: {mode: 'Disabled'}}}
resource db 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-01' = {name: '${mysql.name}/${dbName}' properties: {}}
resource fwAll 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-12-01' = if (allowAllIps) {name: '${mysql.name}/allowAll' properties: {startIpAddress: '0.0.0.0' endIpAddress: '255.255.255.255'}}
resource fwClient 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-12-01' = if (!allowAllIps && clientIp != '') {name: '${mysql.name}/allowClient' properties: {startIpAddress: clientIp endIpAddress: clientIp}}
resource caEnv 'Microsoft.App/managedEnvironments@2024-02-02' = {name: '${namePrefix}-env' location: location properties: {workloadProfiles: [{name: 'Consumption' workloadProfileType: 'Consumption' minimumCount: 0 maximumCount: 1}]}}
resource app 'Microsoft.App/containerApps@2024-02-02' = {name: '${namePrefix}-app' location: location properties: {managedEnvironmentId: caEnv.id configuration: {ingress: {external: true targetPort: 80 transport: 'auto'} secrets: [{name: 'db-pass' value: dbAdminPassword}]} template: {containers: [{name: 'web' image: containerImage resources: {cpu: containerCpu memory: '${containerMemoryGi}Gi'} env: [{name: 'DB_HOST' value: reference(mysql.id, '2023-12-01').fullyQualifiedDomainName},{name: 'DB_PORT' value: '3306'},{name: 'DB_NAME' value: dbName},{name: 'DB_USER' value: dbAdminUser},{name: 'DB_PASS' secretRef: 'db-pass'}]}] scale: {minReplicas: 0 maxReplicas: 1}}}}
output appFqdn string = app.properties.configuration.ingress.fqdn
output mysqlFqdn string = reference(mysql.id, '2023-12-01').fullyQualifiedDomainName
