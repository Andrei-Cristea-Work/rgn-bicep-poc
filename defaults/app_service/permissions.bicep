// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

param userManagedIdentityId string
param userManagedIdentityPrincipalId string

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------
var keyVaultRoleDefinitionID = '4633458b-17de-408a-b874-0445c86b69e6' //This is the built-in "Key Vault Secrets User" role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-secrets-user


// ================================================================================================================
// KEY VAULT
// ================================================================================================================
param vaultName string

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: vaultName
}

resource keyVaultRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: keyVaultRoleDefinitionID
}

resource vaultPermission 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userManagedIdentityId, keyVaultRoleDefinitionID)
  scope: vault
  properties: {
    description: 'Allows the API function to read from Key Vault'
    roleDefinitionId: keyVaultRoleDefinition.id
    principalId: userManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
