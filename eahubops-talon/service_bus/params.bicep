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
      //appliesTo: ['servicebus','storageaccounts']
    }
    {
      name: 'rgn-${env}-zweus-rgnoccint-10-${west_o}-16-0_20-vnet'
      resourceGroup: 'ets-${env}-zweus-network-rgn-rgnoccint-rg'
      subnets: [
        'rgn-${env}-zweus-rgnoccintpaas2'
      ]
      //appliesTo: ['servicebus','storageaccounts']
    }
  ]
  
  allowedIps: concat(aaIpRanges)
  
  serviceBusTopics: [
    'pax-count-yx-fw'
    'pax-count-all-fw'
    'opsflifo-yx-fw'
    'pax-count-zw-fw'
    'pax-count-oo-fw'
    'mvtflifo-all-fw'
    'opsflifo-all-fw'
    'opsflifo-oo-fw'
    'opsflifo-zw-fw'
  ]
  
  serviceBusRouterTopic: 'pax-count-opsflifo-router'

  serviceBusRouterSubs: [
    'pax-count-yx-fw'
    'pax-count-all-fw'
    'opsflifo-yx-fw'
    'pax-count-zw-fw'
    'pax-count-oo-fw'
    'replication-1'
    'opsflifo-all-fw'
    'opsflifo-zw-fw'
    'opsflifo-oo-fw'
    'mvtflifo-all-fw'
  ]
  serviceBusFilters: [
    'MsgType=\'PAX\' AND Airline=\'YX\''
    'MsgType=\'PAX\''
    'MsgType=\'OPSFLIFO\''
    'MsgType=\'PAX\' AND Airline=\'ZW\''
    'MsgType=\'PAX\' AND Airline=\'OO\''
    'replication IS NULL'
    'MsgType=\'OPSFLIFO\''
    'MsgType=\'OPSFLIFO\''
    'MsgType=\'OPSFLIFO\''
    'MsgType=\'MVTFLIFO\''

  ]
}

var sbus_params_east = {
  
  // serviceBus Details
  serviceBusName: 'rgn-${env}-zeaus-pocsbus-sbus'
} 

var sbus_params_west = {
  
  // serviceBus Details
  serviceBusName: 'rgn-${env}-zweus-pocsbus-sbus'
}
// OUTPUTS
// ==================================
output config object = params
output config_east object = sbus_params_east
output config_west object = sbus_params_west
