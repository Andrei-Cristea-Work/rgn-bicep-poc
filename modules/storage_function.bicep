// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

@description('Region location')
param location string = resourceGroup().location

param env string
param region string

param storageAccountType string

@description('Storage account name')
param storageName string

param subnets array
param allowedIps array

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// RESOURCES
// --------------------------------------------------------------------------------------------------------


// Networking 
// =================================================================================
resource vnets 'Microsoft.Network/virtualNetworks@2023-05-01' existing = [for (subnet, index) in subnets: {
  name: subnet.vnet
  scope: resourceGroup(subnet.resourceGroup)
}]

resource privateSubnets 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = [for (subnet, index) in subnets: {
  name: subnet.name
  parent: vnets[index]
}]

//resource networkRestrictions 'Microsoft.Storage/storageAccounts@2023-01-01'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [for (subnet, index) in subnets: {
          id: privateSubnets[index].id
          action: 'Allow'
          state: 'Succeeded'
      }]
      // See https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#restrictions-for-ip-network-rules
      // Storage Accounts do not accept /32 ranges but accept single IPs
      ipRules: [for (ip, index) in map(allowedIps, ip => replace(ip, '/32', '')): {
        action: 'Allow'
        value: ip
      }]
    }
  }
}

// --------------------------------------------------------------------------------------------------------
// OUTPUTS
// --------------------------------------------------------------------------------------------------------

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output storageAccountKey string = storageAccount.listKeys().keys[0].value

// troubleshooting
output subnets array = subnets
output allowedIPs array = allowedIps
output storageAccountType string = storageAccountType

