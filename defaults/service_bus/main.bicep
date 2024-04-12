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

module serviceBusEast '../../modules/service_bus.bicep' = {
  name: 'serviceBus-${deployment().name}'
  params: {
    env: env
    region: region
    allowedIps: params.outputs.config.allowedIps
    subnets: subnets
    serviceBusName: params.outputs.config.serviceBusName
    serviceBusTopics: params.outputs.config.serviceBusTopics
    serviceBusRouterTopic: params.outputs.config.serviceBusRouterTopic
    serviceBusFilters: params.outputs.config.serviceBusFilters
    serviceBusRouterSubs: params.outputs.config.serviceBusRouterSubs
  }
}
