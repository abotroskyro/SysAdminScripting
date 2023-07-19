 Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All"

# Define the URI for the device configuration profiles endpoint
$uri = "/beta/deviceManagement/deviceConfigurations"
$response = Invoke-GraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations"


$response.value | ForEach-Object {
   $filename = "{0}.json" -f $_.displayName.trim()
     $_ | ConvertTo-Json -Depth 100 | Out-File $filename
}

