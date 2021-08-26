param customDomain string
param utcValue string = utcNow('u')

var location = resourceGroup().location
var appServicePlanName = '${resourceGroup().name}-asp'
var appServiceName = '${resourceGroup().name}-as'
var CertificateName = '${customDomain}-managedcert'
var appServicePlanId = '${resourceId('Microsoft.Web/serverfarms', appServicePlanName)}'

resource webCertificate 'Microsoft.Web/certificates@2019-08-01' = {
  name: CertificateName
  location: location
  properties: {
    serverFarmId: appServicePlanId
    canonicalName: customDomain
  }
  dependsOn:[
    hostnameBinding
  ]
}

resource hostnameBinding 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
  name: '${appServiceName}/${customDomain}'
  properties: {
    siteName: appServiceName
    hostNameType: 'Verified'
  }
  dependsOn: [
  ]
}

resource nestedCertBinding 'Microsoft.Resources/deployments@2021-01-01' = {
  name: 'nestedCertBinding-${uniqueString(utcValue)}'
  dependsOn:[
    webCertificate
  ]
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: [
        {
          type: 'Microsoft.Web/sites/hostnameBindings'
          name: '${appServiceName}/${customDomain}'
          apiVersion: '2018-11-01'
          location: '${resourceGroup().location}'
          properties: {
            sslState: 'SniEnabled'
            thumbprint: '${reference(resourceId('Microsoft.Web/certificates', CertificateName)).Thumbprint}'
          }
        }
      ]
    }
  }
}
