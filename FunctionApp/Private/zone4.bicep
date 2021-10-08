@description('Describes the environment where the resource is to be deployed.')
@allowed([
  'Dev'
  'Test'
  'Prod'
  'Util'
])
param Environment string
param appName string = 'xxx'
param storageAccessTier string = 'Cool'
param sku string = 'Premium'
param skuCode string = 'P1v2'
param workerSize int = 1


var prefix = substring(toLower(Environment), 0, 1)
var storageAccount = {
  name: storageName
  resourceId: '${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageName}'
  location: location
  type: storageType
}
var settingName_var = '${toLower(hostingPlanName)}-Autoscale'
var targetResourceId = hostingPlanName_resource.id
var vnetName = resourceGroup().tags.vnetName
var zone4SubnetName = resourceGroup().tags.zone4SubnetName
var vnetResourceGroupName = resourceGroup().tags.vnetResourceGroupName
var appinsName = '${resourceGroup().name}-ai'
var hostingPlanName = '${resourceGroup().name}-zone4-asp'
var storageShortName = substring(toLower(functionName), lastIndexOf(functionName, '-')+1)
var storageName = '${prefix}stor${storageShortName}'
var storageLocation = resourceGroup().location
var location = resourceGroup().location
var storageType = 'Standard_ZRS'
var storageKind = 'StorageV2'
var functionName = '${prefix}-func-${appName}'
var dataSubnet = '${prefix}-subnet-data-default'
var onpremIP = ''
var coloIP = ''

//Tag Variables
var CreatedBy = 'ARM'
var CostCenter = '00'
var TechnicalOwner = 'AD-GROUP'
var AppPlatform = 'IT'

resource functionName_resource 'Microsoft.Web/sites@2018-11-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    AppPlatform: AppPlatform
    CostCenter: CostCenter
    Environment: Environment
    TechnicalOwner: TechnicalOwner
    CreatedBy: CreatedBy
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(storageAccount.resourceId, '2015-05-01-preview').key1}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(storageAccount.resourceId, '2015-05-01-preview').key1}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(appinsName_resource.id, '2014-04-01').InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
      ]
      alwaysOn: true
    }
    clientAffinityEnabled: false
    serverFarmId: hostingPlanName_resource.id
    httpsOnly: true
  }
  dependsOn: [
    storageName_resource
    hostingPlanName_resource
    appinsName_resource
  ]
}

resource functionApp_privateNetwork 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: functionName
  dependsOn: [
    functionName_resource
  ]
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${functionName}-private'
        properties: {
          privateLinkServiceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${functionName}'
          groupIds: [
            'sites'
          ]
        }
      }  
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vnetResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${zone4SubnetName}'
    }
  }
}

resource storageBlob_privateNetwork 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: '${storageName}blob'
  dependsOn: [
    storageName_resource
  ]
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${storageName}blob'
        properties: {
          privateLinkServiceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${storageName}'
          groupIds: [
            'blob'
          ]
        }
      }  
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vnetResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${dataSubnet}'
    }
  }
}

resource storageQueue_privateNetwork 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: '${storageName}queue'
  dependsOn: [
    storageName_resource
  ]
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${storageName}queue'
        properties: {
          privateLinkServiceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${storageName}'
          groupIds: [
            'queue'
          ]
        }
      }  
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vnetResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${dataSubnet}'
    }
  }
}

resource storageTable_privateNetwork 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: '${storageName}table'
  dependsOn: [
    storageName_resource
  ]
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${storageName}table'
        properties: {
          privateLinkServiceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/${storageName}'
          groupIds: [
            'table'
          ]
        }
      }  
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vnetResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${dataSubnet}'
    }
  }
}

resource appinsName_resource 'microsoft.insights/components@2015-05-01' = {
  name: appinsName
  kind: 'web'
  location: location
  tags: {
    AppPlatform: AppPlatform
    CostCenter: CostCenter
    Environment: Environment
    TechnicalOwner: TechnicalOwner
    CreatedBy: CreatedBy
  }
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    Flow_Type: 'Bluefield'
  }
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2016-09-01' = {
  sku: {
    tier: sku
    name: skuCode
  }
  name: hostingPlanName
  location: location
  tags: {
    AppPlatform: AppPlatform
    CostCenter: CostCenter
    Environment: Environment
    TechnicalOwner: TechnicalOwner
    CreatedBy: CreatedBy
  }
  properties: {
    name: hostingPlanName
    targetWorkerCount: workerSize
    reserved: false
  }
}

resource storageName_resource 'Microsoft.Storage/storageAccounts@2017-10-01' = {
  sku: {
    name: storageType
  }
  kind: storageKind
  name: storageName
  location: storageLocation
  tags: {
    AppPlatform: AppPlatform
    CostCenter: CostCenter
    Environment: Environment
    TechnicalOwner: TechnicalOwner
    CreatedBy: CreatedBy
  }
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: storageAccessTier
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: onpremIP
        }
        {
          action: 'Allow'
          value: coloIP
        }
      ]
      virtualNetworkRules:[
        {
          action: 'Allow'
          id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${vnetResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${zone4SubnetName}'
        }
      ]
    }
  }
  dependsOn: []
}

resource settingName 'Microsoft.Insights/autoscalesettings@2014-04-01' = {
  name: settingName_var
  location: resourceGroup().location
  properties: {
    profiles: [
      {
        name: 'Auto created scale condition'
        capacity: {
          minimum: '2'
          maximum: '6'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: ''
              metricResourceUri: targetResourceId
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '2'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: ''
              metricResourceUri: targetResourceId
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 20
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '2'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
    enabled: true
    targetResourceUri: targetResourceId
  }
}
