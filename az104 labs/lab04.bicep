param parLocation string = resourceGroup().location


resource resASGWeb 'Microsoft.Network/applicationSecurityGroups@2024-05-01' = {
  name: 'asg-web'
  location: parLocation
}

resource resNSG 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'myNSG'
  location: parLocation
  properties:{
  securityRules:[
    {
      name: 'AllowASG'
      properties: {
        access: 'Allow'
        sourceApplicationSecurityGroups: [
          {
            id: resASGWeb.id
            location: parLocation
          }
        ]
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRanges: [
          '40'
          '443'
        ]
        direction: 'Inbound'

        priority: 100
        protocol: 'TCP'
        description: 'Allow inbound from ASG'
      }
    }
    {
      name: 'DenyAnyCustom8080Outbound'
      properties:{
        access: 'Deny'
        description: 'Deny all outbound'
        sourceAddressPrefix: '0.0.0.0/0'
        sourcePortRange: '*' 
        destinationPortRange: '8080'
        protocol: '*'
        priority: 4096
        direction: 'Outbound'
        destinationApplicationSecurityGroups:[
          {
            id: resASGWeb.id
            location: parLocation
          }
        ]
      }
    }
  ]
  }
}

resource resCoreServicesVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'contoso.com'
  location: parLocation
  properties:{
    addressSpace: {
      addressPrefixes:[
        '10.20.0.0/16'
      ]
    }
  subnets:[
    {
      name: 'DatabaseSubnet'
      properties:{
        addressPrefix: '10.20.20.0/24'
      }
    }
    {
      name: 'SharedServicesSubnet'
      properties:{
        addressPrefix: '10.20.10.0/24'
        networkSecurityGroup:{
          id: resNSG.id
        }
      }

    }
  ]
  }
}

resource resManufacturingVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'private.contoso.com'
  location: parLocation
  properties:{
    addressSpace: {
      addressPrefixes:[
        '10.30.0.0/16'
      ]
    }
  subnets:[
    {
      name: 'SensorSubnet2'
      properties:{
        addressPrefix: '10.30.21.0/24'
      }

    }
    {
      name: 'SensorSubnet1'
      properties:{
        addressPrefix: '10.30.20.0/24'
      }
    }
  ]
  }
}

resource resPublicDNS 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: '${uniqueString(resourceGroup().id)}.azurequickstart.org'
  location: 'global'

  resource resPublicDNSRecord 'A@2018-05-01' = {
    name: 'www'
    properties: {
      TTL: 3600
      ARecords: [
        {
          ipv4Address: '10.1.1.4'
        }
      ]
    }
  }
}


resource resPrivateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  dependsOn:[
    resManufacturingVnet
  ]
  location: 'global'
  name: '${uniqueString(resourceGroup().id)}.private.azurequickstart.org'

  resource resPrivateDNSZoneLink 'virtualNetworkLinks@2024-06-01' = {
    name: 'manufacturing-link'
    location: 'global'
    properties: {
      registrationEnabled: true
      virtualNetwork: {
        id: resManufacturingVnet.id
      }
    }
  }
  resource resPrivateDNSRecord 'A@2024-06-01' = {
    name: 'sensorvm'
    properties: {
      ttl: 1
      aRecords:[{
        ipv4Address:'10.1.1.4'
      }
      ]
    }
  }
}



