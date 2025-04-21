param parLocation string = resourceGroup().location

////////// Vnet

param parVnetName string

@description('Vnet range e.g. 10.0.0.0/16')

param parSubnetName string

@description('Subnet range e.g 10.0.1.0/24')

////////// VM + NIC

// Naming
param parVMNamePrefix string

param parVMName string = take('${parVMNamePrefix}-${newGuid()}',15)

// Admin username & pass
@description('Username for the Virtual Machine.')
param parAdminUsername string = 'andriusadmin'

param parAdminPassword string

// VM SKUs
@description('The size of the VM')
param parvmSize string = 'Standard_D2s_v3'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param parOSVersion string = '2022-datacenter-azure-edition'

var parosDiskType = 'Standard_LRS'

// Custom script extension

param parScriptExtension string

param parLBName string

resource resNIC 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nic-${parVMName}'
  location: parLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', parVnetName, parSubnetName)
          }
          loadBalancerBackendAddressPools:[
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', parLBName, 'backendLB')
            }
          ]
        }
      }
    ]
    enableIPForwarding: false
  }
}

resource resVM 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: parVMName
  location: parLocation
  properties: {
    hardwareProfile: {
      vmSize: parvmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: parosDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: parOSVersion
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
      computerName: parVMName
      adminUsername: parAdminUsername
      adminPassword: parAdminPassword
    }

    
  }

  resource resVMCUstomScriptExtension 'extensions@2023-03-01' = {
    name: 'Extension-${parVMName}'
    location: resourceGroup().location
    properties: {
      autoUpgradeMinorVersion: true
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.7'
      settings: {
        commandToExecute: parScriptExtension
      }
      protectedSettings: {}
    }
  }
}

output VMName string = parVMName
