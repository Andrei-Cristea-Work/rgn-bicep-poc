// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

param userManagedIdentityId string
param userManagedIdentityPrincipalId string

param systemManagedIdentityId string
param systemManagedIdentityPrincipalId string

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------

// ================================================================================================================
// KEY VAULT
// ================================================================================================================
param vaultName string
param vaultRG string

module keyVualtRBAC '../../../modules/keyvault_perm.bicep' ={
  name:  'kvp-${deployment().name}'
  scope: resourceGroup(vaultRG )
  params:{
    vaultName: vaultName
    userManagedIdentityId: userManagedIdentityId
    userManagedIdentityPrincipalId:userManagedIdentityPrincipalId
    systemManagedIdentityId: systemManagedIdentityId
    systemManagedIdentityPrincipalId: systemManagedIdentityPrincipalId
  }
}
// ================================================================================================================
// SERVICE BUS
// ================================================================================================================

param serviceBusNamespace string

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  scope: resourceGroup()
  name: serviceBusNamespace
}

resource serviceBusWriterRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
}

resource sbusRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userManagedIdentityId, serviceBusWriterRole.id, serviceBusWriterRole.id)
  scope: serviceBus
  properties: {
    description: 'Allows Function to write to SBus'
    roleDefinitionId: serviceBusWriterRole.id
    principalId: userManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

