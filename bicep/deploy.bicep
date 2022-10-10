param location string = resourceGroup().location
param isExternalIngress bool = true
param revisionMode string = 'multiple'
param environmentName string
param containerAppName string
param imageName string
param tagName string
param revisionSuffix string
param oldRevisionSuffix string
param acrUserName string
@secure()
param acrSecret string

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: environmentName
}

module apps 'api.bicep' = {
  name: 'container-apps'
  params: {
    containerAppName: containerAppName
    location: location
    environmentId: environment.id
    imageName: imageName
    tagName: tagName
    revisionSuffix: revisionSuffix
    oldRevisionSuffix: oldRevisionSuffix
    revisionMode: revisionMode
    isExternalIngress: isExternalIngress
    acrUserName: acrUserName
    acrSecret: acrSecret
  }
}
