
// --------------------------------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------------------------------

param location string = resourceGroup().location
param hostingPlanName string 
param planZoneRedundant bool

// --------------------------------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------------------------------

var env = substring(resourceGroup().name, 4, 1)
var region = substring(resourceGroup().name, 7, 4)

// --------------------------------------------------------------------------------------------------------
// RESOURCES
// --------------------------------------------------------------------------------------------------------

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  kind: 'linux'
  location: location
  tags: {
  }
  properties: {
    //serverFarmId: 11826
    name: hostingPlanName
    workerSize: 'Default'
    workerSizeId: 0
    currentWorkerSize: 'Default'
    currentWorkerSizeId: 0
    currentNumberOfWorkers: 1
    planName: 'VirtualDedicatedPlan'
    computeMode: 'Dedicated'
    perSiteScaling: false
    elasticScaleEnabled: false
    //maximumElasticWorkerCount: 1
    isSpot: false
    tags: {
    }
    kind: 'linux'
    reserved: true
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: planZoneRedundant
  }
  sku: {
    name: 'P1v3'
    size: 'P1v3'
    tier: 'PremiumV3'
    family: 'Pv3'
    capacity: ((planZoneRedundant == true) ? 3 : 1)
  }
}

// OUTPUTS
// ==================================
output hostingPlanId string = hostingPlan.id
output hostingPlanName string = hostingPlan.name
