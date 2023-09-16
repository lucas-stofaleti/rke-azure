@description('Location for all resources.')
param location string = resourceGroup().location

@description('Node password.')
@secure()
param adminPassword string

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
]
var nsgName = 'NSG-DEFAULT'
var masterNodes = [
  {
    name: 'MASTER01'
    privateIP: '10.0.0.5'
    vnetName: 'VNET-RKE'
    subnetName: 'SUB-MASTER'
  }
]
var workerNodes = [
  {
    name: 'WORKER01'
    privateIP: '10.0.1.5'
    vnetName: 'VNET-RKE'
    subnetName: 'SUB-WORKER'
  }
  {
    name: 'WORKER02'
    privateIP: '10.0.1.6'
    vnetName: 'VNET-RKE'
    subnetName: 'SUB-WORKER'
  }
]
var cloudInit = base64(loadTextContent('./scripts/cloudinit.yaml'))
var adminUsername = 'lucas'

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
}

module masterNode './compute/node.bicep' = {
  name: 'masterCompute'
  params: {
    location: location
    nodes: masterNodes
    cloudInit: cloudInit
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
  dependsOn: [network]
}

module workerNode './compute/node.bicep' = {
  name: 'workerCompute'
  params: {
    location: location
    nodes: workerNodes
    cloudInit: cloudInit
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
  dependsOn: [network]
}
