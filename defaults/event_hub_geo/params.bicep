//PARAMETERS
// ==================================
param env string
param region_east string
param region_west string

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

var params = {
  vnets: [
    {
      name: 'rgn-${env}-zeaus-rgnoccint-10-${east_o}-16-0_20-vnet'
      resourceGroup: 'ets-${env}-zeaus-network-rgn-rgnoccint-rg'
      subnets: [
        'rgn-${env}-zeaus-rgnoccintpaas2'
      ]
      //appliesTo: ['servicebus', 'eventhubs','storageaccounts']
    }
    {
      name: 'rgn-${env}-zweus-rgnoccint-10-${west_o}-16-0_20-vnet'
      resourceGroup: 'ets-${env}-zweus-network-rgn-rgnoccint-rg'
      subnets: [
        'rgn-${env}-zweus-rgnoccintpaas2'
      ]
      //appliesTo: ['servicebus', 'eventhubs','storageaccounts']
    }
  ]
  
  allowedIps: concat(aaIpRanges)
  
  // EventHub Details
  eventHubList: [
    'testeh1'
    'testeh2'
  ]
  consumerGroupList: [
    'consumer1'
    'consumer2'
  ]
}

var eh_params_east = {
  
  // EventHub Details
  eventHubName: 'rgn-${env}-zeaus-poceh-eh'
} 

var eh_params_west = {
  
  // EventHub Details
  eventHubName: 'rgn-${env}-zweus-poceh-eh'
}

// OUTPUTS
// =======================================
output config object = params
output config_east object = eh_params_east
output config_west object = eh_params_west
