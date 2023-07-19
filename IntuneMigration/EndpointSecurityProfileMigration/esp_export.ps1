# Authenticate with Microsoft Graph API
 Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All" -Environment USGov

# Define the URI for the endpoint security policies endpoint
$uri = "/beta/deviceManagement/intents"

# Define the location to save the JSON files
$jsonFilesPath = "C:\Users\Username\Documents\esp_exports"

# Make the API request to export endpoint security policies
$response = Invoke-GraphRequest -Method GET -Uri $uri

# Loop through each endpoint security policy and export it to a JSON file
$response.value  |ForEach-Object {
    $filename = "{0}.json" -f $_.displayName.trim()
    $_ | ConvertTo-Json -Depth 100 | Out-File "$jsonFilesPath\$filename"
    Write-Host "Exported endpoint security policy $filename"
}
