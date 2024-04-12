// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

@description('Region location')
param location string = resourceGroup().location

param env string
param region string

param eventHubName string

param subnets array
param allowedIps array
param eventHubList array
param consumerGroupsList array

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

resource namespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: eventHubName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 1 //throughput unit 
  }
  properties: {
    zoneRedundant: region == 'eaus' // no zone-redundancy available in West US
  }
}

resource networkRestrictions 'Microsoft.EventHub/namespaces/networkRuleSets@2021-11-01' = {
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


// EventHubs
// =================================================================================
resource eventHubs 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = [for (ehname, index) in eventHubList: if (region == 'eaus') {
  parent: namespace
  name: ehname
  properties: {
    messageRetentionInDays: 7
    partitionCount: 4
  }
}]

// Consumer Groups
// =================================================================================
resource consumerGroups 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-11-01' = [for (cg, index) in consumerGroupsList: if (region == 'eaus') {
  name: cg
  parent: eventHubs[index]
}]

// Permissions
// =================================================================================
resource eventHubDataReaderRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
}

resource eventHubDataWriterRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '2b629674-e913-4c01-ae53-ef4638d8f975'
}


// --------------------------------------------------------------------------------------------------------
// OUTPUTS
// --------------------------------------------------------------------------------------------------------
output namespaceName string = namespace.name
output namespaceId string = namespace.id
