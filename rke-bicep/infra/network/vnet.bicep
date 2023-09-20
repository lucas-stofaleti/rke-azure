@description('Location for all resources.')
param location string

@description('VNET name.')
param virtualNetworkName string

@description('VNET address.')
param virtualNetworkAddress string

@description('Subnets configuration.')
param subnets array

@description('NSG name.')
param nsgName string

@description('NSG rules.')
param securityRules array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddress
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.prefix
        networkSecurityGroup: {
          id: nsg.id
        }
      }
    }]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
}
