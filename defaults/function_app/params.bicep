
//Resources
// ==================================
resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'rgn-${env}-zeaus-rgnoccint-poc-id'
  scope: resourceGroup('rgn-n-zeaus-rgnoccint-poc-rg')
}

//PARAMETERS
// ==================================
param env string
param region string

// VARIABLES
// ==================================
var aaIpRanges = [
  // On-prem
  '144.9.0.0/16'
  '162.92.0.0/16'
  // East
  '52.224.146.231/32'
  '20.253.101.192/28'
  // West
  '13.83.147.126/32'
  '13.86.228.48/28'
]

var east_o = env == 'p'? '16' : '18'
var west_o = env == 'p'? '124' : '126'

// TO DO - centralize global params from below
var globalParams = {
  keyVaultName :'rgn-${env}-zeaus-rgnoccpoc-kv'
  keyVaultRG :'rgn-${env}-zeaus-rgnoccint-poc-rg'
}

var params = (region == 'eaus' ? {
  vnets: [
    {
      name: 'rgn-${env}-zeaus-rgnoccint-10-${east_o}-16-0_20-vnet'
      resourceGroup: 'ets-${env}-zeaus-network-rgn-rgnoccint-rg'
      subnets: [
        'rgn-${env}-z${region}-rgnoccintpaas2'
      ]
      //appliesTo: ['servicebus', 'eventhubs','storageaccounts']
    }
  ]
  
  allowedIps: concat(aaIpRanges)

  // Storage Details
  storageType: 'Standard_ZRS'
  storageName: 'rgn${env}z${region}pocstsa'
  
  // VNet Details
  vnetName: 'rgn-${env}-zeaus-rgnoccint-10-${east_o}-16-0_20-vnet'
  vnetResourceGroup: 'ets-${env}-zeaus-network-rgn-rgnoccint-rg'
  
  // Function Details
  planName: 'rgn-${env}-z${region}-pocplan-plan'
  planZoneRedundant: false
  function1Name: 'rgn-${env}-z${region}-pocfunc1-fa'
  function1SubnetName: 'rgn-${env}-zeaus-rgnoccintpaas2'
} : {
  vnets: [
    {
      name: 'rgn-${env}-zweus-rgnoccint-10-${west_o}-16-0_20-vnet'
      resourceGroup: 'ets-${env}-zweus-network-rgn-rgnoccint-rg'
      subnets: [
        'rgn-${env}-z${region}-rgnoccintpaas2'
      ]
      //appliesTo: ['servicebus', 'eventhubs','storageaccounts']
    }
  ]
  
  allowedIps: concat(aaIpRanges)

  // Storage Details
  storageType: 'Standard_LRS'
  storageName: 'rgn${env}z${region}pocstsa'
  
  //VNet Details
  vnetName: 'rgn-${env}-zweus-rgnoccint-10-${west_o}-16-0_20-vnet'
  vnetResourceGroup: 'ets-${env}-zweus-network-rgn-rgnoccint-rg'
  
  // Function Details
  planName: 'rgn-${env}-z${region}-pocplan-plan'
  planZoneRedundant: false
  function1Name: 'rgn-${env}-z${region}-pocfunc1-fa'
  function1SubnetName: 'rgn-${env}-z${region}-rgnoccintpaas2'
})

// OUTPUTS
// ==================================
output config object = params
output globalConfig object = globalParams

output userManagedIdentityId string = userManagedIdentity.id
output userManagedIdentityPrincipalId string = userManagedIdentity.properties.principalId
