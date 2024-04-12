// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

@description('Region location')
param location string = resourceGroup().location

param env string
param region string

@description('Storage account name')
param storageName string

param blobContainers array

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------
// RESOURCES
// --------------------------------------------------------------------------------------------------------

// Existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageName
}

// Create blob service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

// Create container
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for (containerName, index) in blobContainers:{
  name: containerName
  parent: blobService
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

// --------------------------------------------------------------------------------------------------------
// OUTPUTS
// --------------------------------------------------------------------------------------------------------

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output storageAccountKey string = storageAccount.listKeys().keys[0].value
