// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

@description('Region location')
param location string = resourceGroup().location

param env string
param region string

param vnetName string
param vnetRG string
param privateSubnetName string

param peName string
param peType string
param peLinkedServiceId string

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------

var privateEndpointSubnetId = '${vnet.id}/subnets/${privateSubnetName}'

// --------------------------------------------------------------------------------------------------------
// RESOURCES
// --------------------------------------------------------------------------------------------------------


// Networking 
// =================================================================================
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetRG)
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: peName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: peName
        properties: {
          privateLinkServiceId: peLinkedServiceId
          groupIds: [
            '${peType}'
          ]
        }
      }
    ]
    customNetworkInterfaceName: '${peName}-nic'
  }
}
