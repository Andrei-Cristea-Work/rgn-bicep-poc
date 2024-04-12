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

module hostingPlan '../../modules/hosting_plan.bicep' = {
  name: 'hostingPlan-${deployment().name}'
  params: {
    hostingPlanName: params.outputs.config.planName
    planZoneRedundant: params.outputs.config.planZoneRedundant
  }
}

module appService '../../modules/app_service.bicep' = {
  dependsOn: [hostingPlan]
  name: 'appService-${deployment().name}'
  params: {
      appName: params.outputs.config.app1Name
      appSubnetName: params.outputs.config.app1SubnetName
      vnetName: params.outputs.config.vnetName
      vnetRG: params.outputs.config.vnetResourceGroup
      hostingPlanName: hostingPlan.outputs.hostingPlanName
      hostingPlanId: hostingPlan.outputs.hostingPlanId
      allowedIps: params.outputs.config.allowedIps
  }
}

module privateEndpoint '../../modules/private_endpoint.bicep' = {
  dependsOn: [appService]
  name: 'privateEndpoint-${deployment().name}'
  params: {
    env: env
    region: region
    vnetName: params.outputs.config.vnetName
    vnetRG: params.outputs.config.vnetResourceGroup
    privateSubnetName:params.outputs.config.vnetPrivateEndpointSubnet
    peName: params.outputs.config.privateEndpointName
    peType: params.outputs.config.privateEndpointType
    peLinkedServiceId: appService.outputs.appServiceId
  }
}

