//param stopped bool
//param debug bool

var env = substring(resourceGroup().name, 4, 1)
var rgName = substring(resourceGroup().name, 12, length(resourceGroup().name) - 15)

var eventHubEastRG = resourceGroup().name
var region_east = substring(eventHubEastRG, 7, 4)

var eventHubWestRG = 'rgn-${env}-zweus-${rgName}-rg'
var region_west = substring(eventHubWestRG, 7, 4)

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
    region_east: region_east
    region_west: region_west
  }
}

//East Service Bus Namespace
module serviceBusEast '../../modules/service_bus.bicep' = {
  name: 'serviceBusEa-${deployment().name}'
  scope: resourceGroup(eventHubEastRG)
  params: {
    env: env
    region: region_east
    allowedIps: params.outputs.config.allowedIps
    subnets: subnets
    serviceBusName: params.outputs.config_east.serviceBusName
    serviceBusTopics: params.outputs.config.serviceBusTopics
    serviceBusRouterTopic: params.outputs.config.serviceBusRouterTopic
    serviceBusFilters: params.outputs.config.serviceBusFilters
    serviceBusRouterSubs: params.outputs.config.serviceBusRouterSubs
  }
}

//West Service Bus Namespace
module serviceBusWest '../../modules/service_bus.bicep' = {
  name: 'serviceBusWe-${deployment().name}'
  scope: resourceGroup(eventHubWestRG)
  params: {
    env: env
    region: region_west
    allowedIps: params.outputs.config.allowedIps
    subnets: subnets
    serviceBusName: params.outputs.config_west.serviceBusName
    serviceBusTopics: params.outputs.config.serviceBusTopics
    serviceBusRouterTopic: params.outputs.config.serviceBusRouterTopic
    serviceBusFilters: params.outputs.config.serviceBusFilters
    serviceBusRouterSubs: params.outputs.config.serviceBusRouterSubs
  }
}

//Set up Geo Replication and Alias
resource primaryServiceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: 'rgn-${env}-zeaus-pocsbus-sbus'
}

//Geo replication between Service Busses
resource serviceBusGeo 'Microsoft.ServiceBus/namespaces/disasterRecoveryConfigs@2021-11-01' = {
  name: 'rgn-${env}-pocsbus-sbus'
  parent: primaryServiceBus
  properties: {
    //alternateName: 'string'
    partnerNamespace: serviceBusWest.outputs.namespaceId
  }
  dependsOn: [
    serviceBusEast
    serviceBusWest
  ]
}
