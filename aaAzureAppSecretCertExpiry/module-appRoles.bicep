extension microsoftGraphV1
param __MIId string
param __appRoles array

resource graphSpn 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: '00000003-0000-0000-c000-000000000000'
}

resource assignAppRole 'Microsoft.Graph/appRoleAssignedTo@v1.0' = [for appRole in __appRoles: {
  appRoleId: (filter(graphSpn.appRoles, role => role.value == appRole)[0]).id
  principalId: __MIId
  resourceId: graphSpn.id
}]
