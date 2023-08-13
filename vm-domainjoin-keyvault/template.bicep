targetScope = 'subscription'

var location = 'japaneast'

param vmResourceGroupName string = 'rgVm001'
param vnetResourceGroup string = 'rgVnetJe01'
param existingVnetName string = 'vnetJe01'
param existingSubnetName string = 'Subnet01'
param vmName string

@allowed([
  'windowsserver2019'
  'windowsserver2022'
])
param windowsVersion string = 'windowsserver2019'

@allowed([
  'Standard_B2ms'
  'Standard_B4ms'
  'Standard_D2ads_v5'
  'Standard_D4ads_v5'
])
param vmSize string = 'Standard_B2ms'

param vmUserName string = 'azureuser'
@secure()
param vmPass string

@allowed([
  'PremiumV2_LRS'
  'Premium_LRS'
  'Premium_ZRS'
  'StandardSSD_LRS'
  'StandardSSD_ZRS'
  'Standard_LRS'
  'UltraSSD_LRS'
])
param storageType string = 'StandardSSD_LRS'
param domainToJoin string = 'example.com'
param ouPath string = 'OU=Servers,DC=example,DC=com'

var kvSubscriptionId = '<your-subscription-id>'
var kvResourceGroup = '<key-vault-resource-group-name>'
var kvName = '<key-vault-name>'
var domainUsername = '<domain-admin-username>'

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
  scope: resourceGroup(kvSubscriptionId, kvResourceGroup)
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: vmResourceGroupName
  location: location
}

module vm './vm-main.bicep' = {
  name: 'vm'
  scope: rg
  params: {
    domainUsername: domainUsername
    domainPassword: kv.getSecret('domainPassword')
    vmPass: vmPass
    vnetResourceGroup: vnetResourceGroup
    existingVnetName: existingVnetName
    existingSubnetName: existingSubnetName
    vmName: vmName
    windowsVersion: windowsVersion
    vmUserName: vmUserName
    storageAccountType: storageType
    vmSize: vmSize
    domainToJoin: domainToJoin
    ouPath: ouPath
  }
}
