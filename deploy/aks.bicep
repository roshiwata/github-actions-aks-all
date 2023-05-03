@description('Resource Deployment Location.')
param location string = resourceGroup().location

@description('AKS Cluster Name')
param clusterName string = 'github-actions-aks-all-cluster'

@description('AKS Cluster Managed Identity Name')
param managedIdName string = guid(clusterName)

@description('VNET Name Prefix')
param VNetAddressPrefix string = '10.10.0.0/16'

@description('SUBNET Name Prefix')
param SubnetAddressPrefix string = '10.10.1.0/24'

resource AKSVNet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vn-${clusterName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        VNetAddressPrefix
      ]
    }
  }
}

resource AKSSubNet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' = {
  name: 'sn-${clusterName}'
  parent: AKSVNet // https://githubmemory.com/repo/Azure/bicep/issues/1972
  properties: {
    addressPrefix: SubnetAddressPrefix
  }
}

// ユーザー割り当て Managed ID の作成
resource ManagedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdName
  location: location
}

// ロールの作成と割り当て
@description('A new GUID used to identify the role assignment')
param roleNameGuid string = guid(managedIdName)

resource RoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleNameGuid
  scope: AKSSubNet
  properties: {
    roleDefinitionId: subscriptionResourceId(subscription().subscriptionId,'Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: ManagedId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


// //　AKS Cluster の作成
// resource aks 'Microsoft.ContainerService/managedClusters@2021-08-01' = {
//   name: clusterName
//   location: location
//   identity: {
//     type: 'UserAssigned'
//     // userAssignedIdentities: ManagedIdと指定するとデプロイできない。
//     // https://stackoverflow.com/questions/64877861/the-template-function-reference-is-not-expected-at-this-location
//     userAssignedIdentities: {
//       '${ManagedId.id}': {}
//     }
//   }
//   properties: {
//     dnsPrefix: clusterName
//     enableRBAC: true
//     agentPoolProfiles: [
//       {
//         name: 'agentpool1'
//         count: 2
//         vmSize: 'standard_d2s_v3'
//         mode: 'System'
//         vnetSubnetID: AKSSubNet.id
//       }
//     ]
//   }
// }

// // ACRの作成
// @description('Provide a globally unique name of your Azure Container Registry')
// param acrName string = 'githubactionsaksallacrwaka'

// @description('Provide a tier of your Azure Container Registry.')
// param acrSku string = 'Basic'

// resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
//   name: acrName
//   location: location
//   sku: {
//     name: acrSku
//   }
//   properties: {
//     adminUserEnabled: true
//   }
// }

// //https://docs.microsoft.com/ja-jp/azure/role-based-access-control/built-in-roles
// // var roleAcrPull = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// resource assignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   name: guid(resourceGroup().id, acrName, aks.id, 'AssignAcrPullToAks')
//   scope: acr
//   properties: {
//     description: 'Assign AcrPull role to AKS'
//     principalId: aks.properties.identityProfile.kubeletidentity.objectId //https://github.com/Azure/bicep/discussions/3181
//     principalType: 'ServicePrincipal'
//     // roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleAcrPull}'
//     roleDefinitionId: subscriptionResourceId(subscription().subscriptionId,'Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
//   }
//   // dependsOn: [
//   //   aks
//   // ]
// }
