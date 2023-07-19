Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All" -Environment USGov -TenantId


$intuneManagementScripts = Invoke-GraphRequest -Method GET -Uri "/beta/deviceManagement/deviceManagementScripts"
$intuneManagementScripts.value | ForEach-Object {

$intuneManagementScriptscontent = Invoke-GraphRequest -Method GET -Uri "/beta/deviceManagement/deviceManagementScripts/$($_.id)"
Write-Output $_.scriptContent
Write-Output $intuneManagementScriptscontent.id
$intuneManagementScriptscontent  | ForEach-Object {
$createdDateTime = $_.createdDateTime.ToString("yyyy-MM-ddTHH:mm:ss.ffffffzzz")
$lastModifiedDateTime = $_.lastModifiedDateTime.ToString("yyyy-MM-ddTHH:mm:ss.ffffffzzz")
$jsonfile = $_.displayName
$requestBody = @{
executionFrequency = 	$_.executionFrequency 
displayName = $_.displayName
description = $_.description
scriptContent = $_.scriptContent
createdDateTime = $createdDateTime
lastModifiedDateTime = $lastModifiedDateTime
runAsAccount = $_.runAsAccount
enforceSignatureCheck = $_.enforceSignatureCheck
fileName = $_.fileName
roleScopeTagIds = $_.roleScopeTagIds



} | ConvertTo-Json -Depth 100 |  Out-File "$jsonfile.json"
Write-Output $requestBody

#$intuneManagementScripts = Invoke-GraphRequest -Method POST -Uri "/beta/deviceManagement/deviceManagementScripts" -Body $requestBody -ContentType "application/json; charset=utf-8"

}

}