@description('Nodes configuration.')
param nodes array

@description('Location for all resources.')
param location string

@description('CloudInit Script.')
param cloudInit string

@description('Admin username.')
param adminUsername string

@description('Node ssh key.')
param sshKey string

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = [for node in nodes: {
  name: 'PIP-${node.name}'
  location: location
  sku: {
    name: 'Basic'
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = [for (node, index) in nodes: {
  name: 'NIC-${node.name}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: node.privateIP
          publicIPAddress: {
            id: pip[index].id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', node.vnetName, node.subnetName)
          }
        }
      }
    ]
  }
}]

resource node 'Microsoft.Compute/virtualMachines@2021-11-01' = [for (node, index) in nodes: {
  name: node.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }       
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[index].id
        }
      ]
    }
    osProfile: {
      computerName: node.name
      adminUsername: adminUsername
      adminPassword: sshKey
      customData: cloudInit
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshKey
            }
          ]
        }
      }
    }
  }
}]
