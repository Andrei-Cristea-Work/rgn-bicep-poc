// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

@description('Region location')
param location string = resourceGroup().location

param env string
param region string

@description('Storage account name')
param storageName string
param fileshareName string

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
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' ={
  name: 'default'
  parent: storageAccount
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: (env == 'p' ? 14 : 2)
    }
  }
}
resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: fileshareName
  parent: fileServices
}

// --------------------------------------------------------------------------------------------------------
// OUTPUTS
// --------------------------------------------------------------------------------------------------------

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output storageAccountKey string = storageAccount.listKeys().keys[0].value
