
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All" -Environment USGov -TenantId 

Get-ChildItem -Path "C:\Users\Users\PathtoJson" -Filter "*.json" | ForEach-Object {

$JSON_Content = Get-Content -Path $_.FullName -Raw

$intuneManagementScripts = Invoke-GraphRequest -Method POST -Uri "/beta/deviceManagement/deviceManagementScripts" -Body $JSON_Content -ContentType "application/json; charset=utf-8"
Write-Output $intuneManagementScripts

}