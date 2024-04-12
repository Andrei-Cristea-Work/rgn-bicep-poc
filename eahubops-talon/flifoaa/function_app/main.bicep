//param stopped bool
//param debug bool


var env = substring(resourceGroup().name, 4, 1)
var region = substring(resourceGroup().name, 7, 4)

var subnets = flatten( // Flatten array of arrays: [Vnets[Subnets]] -> [{...}]
  map(params.outputs.config.vnets,
    vnet => map(vnet.subnets,
      subnet => {
        resourceGroup: vnet.resourceGroup
        vnet: vnet.name
        name: subnet
        //appliesTo: vnet.appliesTo
      }
    )
  )
)

module params 'params.bicep' = {
  name: 'params-${deployment().name}'
  params: {
    env: env
    region: region
  }
}

module storageAccount '../../../modules/storage_function.bicep' = {
  name: 'storage-${deployment().name}'
  params: {
      env: env
      region: region
      storageAccountType: params.outputs.config.storageType
      storageName : params.outputs.config.storageName
      subnets: subnets
      allowedIps: params.outputs.config.allowedIps
  }
}

module hostingPlan '../../../modules/hosting_plan.bicep' = {
  name: 'hostingPlan-${deployment().name}'
  params: {
    hostingPlanName: params.outputs.config.planName
    planZoneRedundant: params.outputs.config.planZoneRedundant
  }
}

module functionApp '../../../modules/function_app.bicep' = {
  dependsOn: [storageAccount,hostingPlan]
  name: 'functionApp-${deployment().name}'
  params: {
      functionName: params.outputs.config.function1Name
      functionSubnetName: params.outputs.config.function1SubnetName
      vnetName: params.outputs.config.vnetName
      vnetRG: params.outputs.config.vnetResourceGroup
      hostingPlanId: hostingPlan.outputs.hostingPlanId
      storageAccountName : storageAccount.outputs.storageAccountName
      storageAccountKey: storageAccount.outputs.storageAccountKey
      allowedIps: params.outputs.config.allowedIps
  }
}


module permissions 'permissions.bicep' ={
  dependsOn: [functionApp,hostingPlan]
  name: 'kv-perms-${deployment().name}'
  params: {
    vaultRG: params.outputs.globalConfig.keyVaultRG
    vaultName: params.outputs.globalConfig.keyVaultName
    serviceBusNamespace: params.outputs.globalConfig.serviceBusName
    userManagedIdentityId:  params.outputs.userManagedIdentityId
    userManagedIdentityPrincipalId: params.outputs.userManagedIdentityPrincipalId
    systemManagedIdentityId:  functionApp.outputs.functionAppID
    systemManagedIdentityPrincipalId: functionApp.outputs.functionAppPrincipalID
  }
}
