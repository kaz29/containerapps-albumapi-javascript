param containerAppName string
param location string = resourceGroup().location
param environmentId string
param imageName string
param tagName string
param revisionSuffix string
param oldRevisionSuffix string
param isExternalIngress bool
param acrUserName string
@secure()
param acrSecret string

@allowed([
  'multiple'
  'single'
])
param revisionMode string = 'single'

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      activeRevisionsMode: revisionMode
      ingress: {
        external: isExternalIngress
        targetPort: 3500
        transport: 'auto'
        allowInsecure: false
        traffic: ((contains(revisionSuffix, oldRevisionSuffix)) ? [
          {
            weight: 100
            latestRevision: true
          }
        ] : [
          {
            weight: 0
            latestRevision: true
          }
          {
            weight: 100
            revisionName: '${containerAppName}--${oldRevisionSuffix}'
          }
        ])
      }
      dapr:{
        enabled:false
      }
      secrets: [
        {
          name: 'acr-secret'
          value: acrSecret
        }
      ]
      registries: [
        {
            server: '${acrUserName}.azurecr.io'
            username: acrUserName
            passwordSecretRef: 'acr-secret'
        }
      ]
    }
    template: {
      revisionSuffix: revisionSuffix
      containers: [
        {
          image: '${acrUserName}.azurecr.io/${imageName}:${tagName}'
          name: containerAppName
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scaling-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
