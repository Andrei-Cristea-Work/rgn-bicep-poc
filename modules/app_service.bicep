
// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

param location string = resourceGroup().location
param appName string
param hostingPlanName string
param hostingPlanId string

//param userManagedIdentityID string
//param userManagedIdentityName string

param appSubnetName string
param vnetName string
param vnetRG string

param allowedIps array

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------

var vnetIntegrationSubnetId = '${vnet.id}/subnets/${appSubnetName}'

// --------------------------------------------------------------------------------------------------------
// RESOURCES
// --------------------------------------------------------------------------------------------------------

// Networking 
// =================================================================================
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing =  {
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

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    //serverFarmId: hostingPlan.id
    serverFarmId: hostingPlanName
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    
    /*ipSecurityRestrictions: [for (ip, index) in allowedIps: {
      ipAddress: ip
      action: 'Allow'
    }]*/

    siteConfig: {
      //netFrameworkVersion: 'v6.0'
      numberOfWorkers: 1
      linuxFxVersion: 'DOTNETCORE|8.0'
      use32BitWorkerProcess: false
      acrUseManagedIdentityCreds: true
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      alwaysOn: true
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertMode: 'Required'
    httpsOnly: true
    storageAccountRequired: false
    virtualNetworkSubnetId: vnetIntegrationSubnetId
    keyVaultReferenceIdentity: 'SystemAssigned'
    //keyVaultReferenceIdentity: userManagedIdentity.id //User managed Identity resource ID
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

// --------------------------------------------------------------------------------------------------------
// OUTPUTS
// --------------------------------------------------------------------------------------------------------
output appServiceName string = appService.name
output appServiceId string = appService.id
output appServicePrincipalID string = appService.identity.principalId

// Troubleshoot
//output vnetIntegrationSubnetId string = vnetIntegrationSubnetId
