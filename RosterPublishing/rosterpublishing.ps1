Connect-AzAccount -Identity
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token
$token = ConvertTo-SecureString "$token" -AsPlainText -Force
Connect-MgGraph -AccessToken $token
$AzureTempDir= $env:TEMP
$AutoRosterFile = "CompanyRosterAuto"
# Start with the Get-MgUser cmdlet with its required parameters
$users = Get-MgUser -Filter "assignedLicenses/`$count ne 0 and userType eq 'Member' and AccountEnabled eq true" -ConsistencyLevel eventual -CountVariable licensedUserCount -All -Property DisplayName,CompanyName,ProxyAddresses,UserPrincipalName,customSecurityAttributes 

# Prepare a Select-Object statement to filter the data
$userData = $users | Select `
    DisplayName, `
    UserPrincipalName, `
    CompanyName, `
    @{Name='mailalias'; Expression={$_.ProxyAddresses -join ';'}}, `
    @{Name='Licenses'; Expression={(Get-MgUserLicenseDetail -UserId $_.UserPrincipalName | Select -expand SkuPartNumber) -join ","}}, `
    @{Name = "PersonalEmail"; Expression={
        Invoke-GraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/users/$($_.UserPrincipalName)?`$select=customSecurityAttributes" -OutputType PSObject |
        Select -ExpandProperty customSecurityAttributes |
        Select -ExpandProperty RosterData |
        Select -ExpandProperty PersonalEmail|
        Out-String
    }}

# Finally, export the result to an Excel file
$userData | Export-Excel -Autosize -Path "$AzureTempDir\$AutoRosterFile.xlsx"
$SPOFolderId = "<SPO FOLDER ID GOES HERE>"
$SiteId = "SPO SITE ID GOES HERE>"
$requestUri = "https://graph.microsoft.com/v1.0/sites/$SiteId/drive/items/$SPOFolderId`:/$AutoRosterFile.xlsx:/content"
Invoke-GraphRequest -Method PUT -Uri $requestUri -ContentType 'multipart/form-data' -InputFilePath "$AzureTempDir\$AutoRosterFile.xlsx"
