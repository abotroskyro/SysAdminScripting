 Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All"

# Loop through each JSON file in the directory
Get-ChildItem -Path "$(pwd)" -Filter "*.json" | ForEach-Object {
$uri = "/beta/deviceManagement/deviceConfigurations"
    # Read the JSON file into a PowerShell object
    $json = Get-Content $_.FullName -Raw | ConvertFrom-Json

    $platformType = ($json.'@odata.type').Split(".")[-1]

    # Create the request body for the API request using the concrete device configuration profile class
    $requestBody = @{
        displayName = $json.displayName.trim()
        description = $json.description
        '@odata.type' = "microsoft.graph.$platformType"
        payload = $json.payload
	  payloadName = $json.payloadName
    }

Write-Output ($requestBody | ConvertTo-Json)
    # Make the API request to import the device configuration profile
   $response = Invoke-GraphRequest -Method POST -Uri $uri -Body ($requestBody | ConvertTo-Json)  -ContentType "application/json; charset=utf-8"

    # Display the response from the API
    Write-Host "Imported device configuration profile $($json.displayName) with ID $($response.id)"
}
