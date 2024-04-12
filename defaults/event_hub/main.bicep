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

module eventHubEast '../../modules/event_hub.bicep' = {
  name: 'eventhub-${deployment().name}'
  params: {
    env: env
    region: region
    eventHubName: params.outputs.config.eventHubName
    allowedIps: params.outputs.config.allowedIps
    subnets: subnets
    eventHubList: params.outputs.config.eventHubList
    consumerGroupsList: params.outputs.config.consumerGroupList
  }
}
