 Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementApps.Read.All,DeviceManagementManagedDevices.Read.All" -Environment USGov

$intuneShellScripts = Invoke-GraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts"
$intuneShellScripts.value |  ForEach-Object {




$intuneShellScriptscontent = Invoke-GraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts/$($_.id)"
Write-Output $_.scriptContent
Write-Output $intuneShellScripts.scriptContent
$intuneShellScriptscontent | ForEach-Object {

$filename = "{0}_shell.json" -f $_.displayName.trim()
     $_ | ConvertTo-Json -Depth 100 | Out-File $filename

}

}











