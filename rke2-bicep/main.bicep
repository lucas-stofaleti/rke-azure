targetScope='subscription'

param resourceGroupName string = 'RG-RKE2'
param location string = 'eastus2'

@description('Node ssh key.')
param sshKey string = loadTextContent('../../../.ssh/id_rsa.pub')

var virtualNetworkName = 'VNET-RKE'
var virtualNetworkAddress = '10.0.0.0/16'
var subnets = [
  {
    name: 'SUB-MASTER'
    prefix: '10.0.0.0/24'
  }
  {
    name: 'SUB-WORKER'
    prefix: '10.0.1.0/24'
  }
]
var securityRules = [
  {
    name: 'SSH'
    properties: {
      priority: 100
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
    }
  }
  {
    name: 'KUBEAPI'
    properties: {
      priority: 200
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '6443'
    }
  }
  // {
  //   name: 'NODEPORT'
  //   properties: {
  //     priority: 300
  //     protocol: 'Tcp'
  //     access: 'Allow'
  //     direction: 'Inbound'
  //     sourceAddressPrefix: '*'
  //     sourcePortRange: '*'
  //     destinationAddressPrefix: '*'
  //     destinationPortRange: '30007'
  //   }
  // }
  {
    name: 'INGRESS-HTTP'
    properties: {
      priority: 400
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
    }
  }
  {
    name: 'INGRESS-HTTPS'
    properties: {
      priority: 500
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
]
var nsgName = 'NSG-DEFAULT'
var masterNodes = [
  {
    name: 'MASTER01'
    privateIP: '10.0.0.5'
    vnetName: 'VNET-RKE'
    subnetName: 'SUB-MASTER'
  }
  {
    name: 'MASTER02'
    privateIP: '10.0.0.6'
    vnetName: 'VNET-RKE'
    subnetName: 'SUB-MASTER'
  }
]
var adminUsername = 'lucas'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location
}

module network './network/vnet.bicep' = {
  name: 'network'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddress: virtualNetworkAddress
    subnets: subnets
    location: location
    securityRules: securityRules
    nsgName: nsgName
  }
  scope: rg
}

module masterNode './compute/node.bicep' = {
  name: 'masterCompute'
  params: {
    location: location
    nodes: masterNodes
    adminUsername: adminUsername
    sshKey: sshKey
  }
  dependsOn: [network]
  scope: rg
}
