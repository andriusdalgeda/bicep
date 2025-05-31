param parLocation string = resourceGroup().location

////////// Vnet

param paramVnetName string

param paramSubnetName string

////////// VM + NIC

// Naming
param paramVMNamePrefix string

@description('Limit name to max chars allowed to avoid issues')
param paramVMName string = take('${paramVMNamePrefix}-${newGuid()}',15)

// Admin username & pass
param paramAdminUsername string

@secure()
param paramAdminPassword string

// VM SKUs
@description('The size of the VM')
param paramvmSize string = 'Standard_D2s_v3'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param paramOSVersion string = '2022-datacenter-azure-edition'

var paramosDiskType = 'Standard_LRS'


resource resNIC 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nic-${paramVMName}'
  location: parLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', paramVnetName, paramSubnetName)
          }
        }
      }
    ]
    enableIPForwarding: false
  }
}

resource resVM 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: paramVMName
  location: parLocation
  properties: {
    hardwareProfile: {
      vmSize: paramvmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: paramosDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: paramOSVersion
        version: 'latest'
        }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resNIC.id
        }
      ]
    }
    osProfile: {
      computerName: paramVMName
      adminUsername: paramAdminUsername
      adminPassword: paramAdminPassword
    }

    
  }
}
