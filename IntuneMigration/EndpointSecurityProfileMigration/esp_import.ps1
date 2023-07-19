# Authenticate with Microsoft Graph API
 Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All" -Environment USGov

# Define the URI for the endpoint security policies endpoint
$uri = "/beta/deviceManagement/intents"

# Define the location of the JSON files containing the endpoint security policies
$jsonFilesPath = "C:\Users\Users\Documents\esp_exports"

# Loop through each JSON file containing an endpoint security policy
Get-ChildItem $jsonFilesPath -Filter "*.json" |ForEach-Object {
    $jsonFile = Get-Content $_.FullName -Raw | ConvertFrom-Json

    # Define the properties of the new endpoint security policy
    $policy = @{
        displayName = $jsonFile.displayName
        description = $jsonFile.description
        isAssigned = $jsonFile.isAssigned
        templateId = $jsonFile.templateId
        roleScopeTagIds = $jsonFile.roleScopeTagIds
    }

    # Create an empty array to hold the settings
    $categorySettings = @()

    # Loop through each category in the policy's template and add its settings to the array
    $categoriesRequest = Invoke-GraphRequest -Method GET -Uri "/beta/deviceManagement/templates/$($policy.templateId)/categories"
    $categories = $categoriesRequest.value
    foreach ($category in $categories) {
        $categorySettingsRequest = Invoke-GraphRequest -Method GET -Uri "/beta/deviceManagement/intents/$($jsonFile.id)/categories/$($category.id)/settings?`$expand=Microsoft.Graph.DeviceManagementComplexSettingInstance/Value"
        $categorySettings += $categorySettingsRequest.value

       
    }

    # Create the request body for the API request
    $requestBody = @{
        #"@odata.type" = "#microsoft.graph.deviceManagementIntent"
        displayName = $policy.displayName
        description = $policy.description
        isAssigned = $false
        templateId = $policy.templateId
        roleScopeTagIds = $policy.roleScopeTagIds
        settingsDelta = $categorySettings
    } | ConvertTo-Json -Depth 10
Write-Output $requestBody
    # Make the API request to create a new endpoint security policy
    $response = Invoke-GraphRequest -Method POST -Uri "/beta/deviceManagement/templates/$($policy.templateId)/createInstance" -Body $requestBody

    # Output the result
    Write-Host "Created endpoint security policy '$($response.displayName)'"
}
