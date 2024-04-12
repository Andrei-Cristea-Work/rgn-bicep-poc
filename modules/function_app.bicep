// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

param location string = resourceGroup().location
param storageAccountName string
param storageAccountKey string

//param userManagedIdentityID string
//param userManagedIdentityName string

param hostingPlanId string
param functionName string
param functionSubnetName string
param vnetName string
param vnetRG string

param allowedIps array

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------

var vnetIntegrationSubnetId = '${vnet.id}/subnets/${functionSubnetName}'

// --------------------------------------------------------------------------------------------------------
// RESOURCES
// --------------------------------------------------------------------------------------------------------


// Networking 
// =================================================================================
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRG)
}

// User Managed Identity
// =================================================================================
/*
resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (region == 'eastus') {
  name: userManagedIdentityName
  location: location
}
*/

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionName
  location: location
  kind: 'functionapp,linux'
  properties: {
    virtualNetworkSubnetId: vnetIntegrationSubnetId
    vnetContentShareEnabled: true
    serverFarmId: hostingPlanId
    siteConfig: {
      vnetRouteAllEnabled: true
      ipSecurityRestrictions: [for (ip, index) in allowedIps: {
        ipAddress: ip
        action: 'Allow'
      }]
      scmIpSecurityRestrictionsUseMain: true
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      //netFrameworkVersion: 'v8.0'
      /*siteProperties: {
        metadata: null
        properties: [
          {
            name: 'LinuxFxVersion'
            value: 'DOTNET-ISOLATED|8.0'
          }
          {
            name: 'WindowsFxVersion'
            value: null
          }
        ]
        appSettings: null
      }*/
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        /*{
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }*/
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
      ]
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      alwaysOn: true
      keyVaultReferenceIdentity: 'SystemAssigned'  
      //keyVaultReferenceIdentity: userManagedIdentity.id //User managed Identity resource ID
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
    
    /*
    type: 'UserAssigned'
    userAssignedIdentities: {
      keyVaultReferenceIdentity: {} //User managed Identity resource ID
    }
    */
  }
}


// OUTPUTS
// ==================================
output functionAppPrincipalID string = functionApp.identity.principalId
output functionAppID string = functionApp.id

// Troubleshoot
output vnetIntegrationSubnetId string = vnetIntegrationSubnetId
