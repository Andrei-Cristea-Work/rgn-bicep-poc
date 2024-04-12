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

module storageAccount '../../modules/storage_account.bicep' = {
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

module blobContainers '../../modules/storage_blobs.bicep' = {
  dependsOn: [storageAccount]
  name: 'blob-${deployment().name}'
  params: {
    env: env
    region: region
    storageName : storageAccount.outputs.storageAccountName
    blobContainers: params.outputs.config.blobContainers
  }
}

module privateEndpoint '../../modules/private_endpoint.bicep' = {
  dependsOn: [storageAccount,blobContainers]
  name: 'privateEndpoint-${deployment().name}'
  params: {
    env: env
    region: region
    vnetName: params.outputs.config.vnetName
    vnetRG: params.outputs.config.vnetResourceGroup
    privateSubnetName:params.outputs.config.vnetPrivateEndpointSubnet
    peName: params.outputs.config.privateEndpointName
    peType: params.outputs.config.privateEndpointType
    peLinkedServiceId: storageAccount.outputs.storageAccountId
  }
}
