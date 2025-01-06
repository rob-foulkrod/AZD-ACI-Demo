@description('The tags to associate with the resource')
param tags object

@description('Name of the ACR to use in the same resource group')
param acrName string

var containerInstanceName = 'aci-${uniqueString(resourceGroup().id, subscription().id)}'

resource registry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2024-10-01-preview' = {
  name: containerInstanceName
  location: resourceGroup().location
  tags: tags  
  properties: {
    ipAddress: {
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
      type: 'Public'
    }
    sku: 'Standard'
    osType: 'Linux'
    imageRegistryCredentials: [
      {
        server: registry.properties.loginServer
        username: registry.listCredentials().username
        password: registry.listCredentials().passwords[0].value
      }
    ]
    containers: [
      {
        name: 'container-${containerInstanceName}'
        properties: {
          image: '${registry.properties.loginServer}/maartenvandiemen/eshoponweb:latest'        
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          environmentVariables: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Docker'
            }
            {
              name: 'UseOnlyInMemoryDatabase'
              value: 'true'
            }
            {
              name: 'ASPNETCORE_HTTP_PORTS'
              value: '80'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
        }
      }
    ]
  }
}
