 Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All,DeviceManagementManagedDevices.ReadWrite.All" -Environment USGov -TenantId <>

# Loop through each JSON file in the directory
Get-ChildItem -Path "$(pwd)" -Filter "*_shell.json" | ForEach-Object {

    # Read the JSON file into a PowerShell object
    $json = Get-Content $_.FullName -Raw | ConvertFrom-Json

$createdDateTime = $json.createdDateTime.ToString("yyyy-MM-ddTHH:mm:ss.ffffffzzz")
$lastModifiedDateTime = $json.lastModifiedDateTime.ToString("yyyy-MM-ddTHH:mm:ss.ffffffzzz")
$requestBody = @{
'@odata.type' = "#microsoft.graph.deviceShellScript"
executionFrequency = $json.executionFrequency
retryCount = $json.retryCount
blockExecutionNotifications = $json.blockExecutionNotifications 
displayName = $json.displayName
description = $json.description
scriptContent = $json.scriptContent
createdDateTime = $createdDateTime
lastModifiedDateTime = $lastModifiedDateTime
runAsAccount = $json.runAsAccount
fileName = $json.fileName
roleScopeTagIds = $json.roleScopeTagIds

} 
#Write-Output $requestBody

$result = Invoke-GraphRequest -Uri "/beta/deviceManagement/deviceShellScripts" -Method POST -ContentType "application/json" -Body ($requestBody | ConvertTo-Json -Depth 100)
Write-Output $result

Write-Output $creationResponse
}
