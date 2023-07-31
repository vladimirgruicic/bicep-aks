param location string = 'westeurope'
param acrName string = 'acrbiceptest'
param sku string = 'Standard'
param keyVaultName string = 'AKSKeyVaultBicep'

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: 'aks-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.0.0.0/16'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = {
  name: 'aks-subnet'
  parent: vnet
  properties: {
    addressPrefix: '192.0.0.0/24'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: 'aks-vnet-nsg'
  location: location
}

resource subnetnsg 'Microsoft.Network/networkSecurityGroups/securityRules@2023-02-01' = {
  name: 'aks-subnet-nsg-rule-port80'
  parent: nsg
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    direction: 'Inbound'
    priority: 1000
  }
  dependsOn: [
    vnet
    subnet
  ]
}

resource aksBicepCluster 'Microsoft.ContainerService/managedClusters@2023-05-01' = {
  name: 'aks-bicep'
  location: location
  properties: {
    dnsPrefix: 'aksbicep'
    kubernetesVersion: '1.25.6'
    agentPoolProfiles: [
      {
        name: 'aksbicep'
        count: 5
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        mode: 'System'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      podCidr: '10.244.0.0/16'
      serviceCidr: '192.0.1.0/24'
      dnsServiceIP:'192.0.1.10'
      networkMode: 'transparent'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
    servicePrincipalProfile: {
      clientId: 'f2302d03-36fe-495a-88a4-72706e17b0b7'
      secret: 'Zlq8Q~jvsHwg3jmhkI1qyQSEcqXoyLP8BsNaAbj8'
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: []    
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: false
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
  }
}
