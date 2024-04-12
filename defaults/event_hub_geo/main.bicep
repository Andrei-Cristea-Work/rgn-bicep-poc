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

//East Event Hub Namespace
module eventHubEast '../../modules/event_hub.bicep' = {
  name: 'eventhubEa-${deployment().name}'
  scope: resourceGroup(eventHubEastRG)
  params: {
    env: env
    region: region_east
    eventHubName: params.outputs.config_east.eventHubName
    allowedIps: params.outputs.config.allowedIps
    subnets: subnets
    eventHubList: params.outputs.config.eventHubList
    consumerGroupsList: params.outputs.config.consumerGroupList
  }
}

//West Event Hub Namespace
module eventHubWest '../../modules/event_hub.bicep' = {
  name: 'eventhubWe-${deployment().name}'
  scope: resourceGroup(eventHubWestRG)
  params: {
    env: env
    region: region_west
    eventHubName: params.outputs.config_west.eventHubName
    allowedIps: params.outputs.config.allowedIps
    subnets: subnets
    eventHubList: params.outputs.config.eventHubList
    consumerGroupsList: params.outputs.config.consumerGroupList
  }
}

//Set up Geo Replication and Alias
resource primaryEventHub 'Microsoft.EventHub/namespaces@2022-01-01-preview' existing = {
  name: 'rgn-${env}-zeaus-poceh-eh'
}

//Geo replication between Event Hubs
resource eventHubGeo 'Microsoft.EventHub/namespaces/disasterRecoveryConfigs@2022-01-01-preview' = {
  name: 'rgn-${env}-poceh-eh'
  parent: primaryEventHub
  properties: {
    //alternateName: 'string'
    partnerNamespace: eventHubWest.outputs.namespaceId
  }
  dependsOn: [
    eventHubEast
    eventHubWest
  ]
}
