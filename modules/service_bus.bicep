// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

@description('Region location')
param location string = resourceGroup().location

param env string
param region string

param serviceBusName string

param subnets array
param allowedIps array
param serviceBusTopics array
param serviceBusRouterSubs array
param serviceBusFilters array
param serviceBusRouterTopic string

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------



// --------------------------------------------------------------------------------------------------------
// RESOURCES
// --------------------------------------------------------------------------------------------------------

// Networking 
// =================================================================================
resource vnets 'Microsoft.Network/virtualNetworks@2023-05-01' existing = [for (subnet, index) in subnets: {
  name: subnet.vnet
  scope: resourceGroup(subnet.resourceGroup)
}]

resource privateSubnets 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = [for (subnet, index) in subnets: {
  name: subnet.name
  parent: vnets[index]
}]

// Namespace
// =================================================================================

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusName
  location: location
  properties: {
    premiumMessagingPartitions: 1
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    privateEndpointConnections: []
    zoneRedundant: false
  }
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 1
  }
}

resource networkRestrictions 'Microsoft.serviceBus/namespaces/networkRuleSets@2021-11-01' = if (region == 'eaus') {
  name: 'default'
  parent: namespace
  properties: {
    defaultAction: 'Deny'
    virtualNetworkRules: [for (subnet, index) in subnets: {
      subnet: {
        id: privateSubnets[index].id
      }
    }]
    ipRules: [for (ip, index) in allowedIps: {
      action: 'Allow'
      ipMask: ip
    }]
    publicNetworkAccess: 'Enabled'
    trustedServiceAccessEnabled: true
  }
}


// serviceBus Topics
// =================================================================================

resource topics 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = [for (type, index) in serviceBusTopics: if (region == 'eaus') {
  parent: namespace
  name: 'rgn-${env}-${type}-topic'
}]

/*resource queues 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = [for (type, index) in serviceBusTypes: if (region == 'eaus') {
  parent: namespace
  name: 'rgn-${env}-${type}-queue'
  properties: {
    defaultMessageTimeToLive: 'P7D'
  }
}]*/

resource topicSubs 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = [for (type, index) in serviceBusTopics: if (region == 'eaus') {
  name: 'rgn-${env}-${type}-sbt'
  parent: topics[index]
  /*properties: {
    forwardTo: routerTopic.name
  }*/
}]

// serviceBus Router Topic

resource routerTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = if (region == 'eaus') {
  parent: namespace
  name: '${serviceBusRouterTopic}-topic'
}

resource routerTopicSubs 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = [for (sub, index) in serviceBusRouterSubs: if (region == 'eaus') {
  name: 'rgn-${env}-${sub}-sbt'
  parent: routerTopic
  properties: {
    forwardTo: ((contains(sub,'fw')) ? 'rgn-${env}-${sub}-topic' : null)
  }
}]

resource routerTopicSubFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = [for (filter, index) in serviceBusFilters: if (region == 'eaus') {
  name: 'rgn-${env}-filter'
  parent: routerTopicSubs[index]
  properties: {
    action: {
      //compatibilityLevel: int
      //requiresPreprocessing: bool
      //sqlExpression: 'string'
    }
    filterType: 'SqlFilter'
    sqlFilter: {
      //compatibilityLevel: int
      sqlExpression: filter
      requiresPreprocessing: false
    }
  }
}]

// --------------------------------------------------------------------------------------------------------
// OUTPUTS
// --------------------------------------------------------------------------------------------------------
output namespaceName string = namespace.name
output namespaceId string = namespace.id
