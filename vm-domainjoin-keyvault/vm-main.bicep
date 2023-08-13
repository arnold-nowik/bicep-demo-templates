// パラメータ定義

param vnetResourceGroup string
param existingVnetName string
param existingSubnetName string
param vmName string 
param vmSize string
param windowsVersion string
param vmUserName string
@secure()
param vmPass string
param storageAccountType string
param domainToJoin string 
param ouPath string 
param domainUsername string
@secure()
param domainPassword string

// 変数

var subnetId = resourceId(vnetResourceGroup,'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingSubnetName)
var image = {
  windowsserver2019: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter'
    version: 'latest'
  }
  windowsserver2022: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-Datacenter'
    version: 'latest'
  }
}

// リソース定義

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmUserName
      adminPassword: vmPass
    }
    storageProfile: {
      imageReference: {
        publisher: image[windowsVersion].publisher
        offer: image[windowsVersion].offer
        sku: image[windowsVersion].sku
        version: image[windowsVersion].version
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: '${vmName}-nic'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource joinDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: vm
  name: 'JoinDomain'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: '${domainToJoin}\\${domainUsername}'
      restart: true
      options: '3'
    }
    protectedSettings: {
      Password: domainPassword
    }
  }
}
