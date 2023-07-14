Param
(
  [Parameter (Mandatory= $true)]
  [String] $OffUser, ##no default, requires upn (email address)
  [Parameter (Mandatory= $false)]
  [String] $toTransfer="<OID HERE>"
)
#
$spConnection = Get-AutomationConnection -Name AzureRunAsConnection
$MyTenantId=$spConnection.TenantId
Import-Module Microsoft.Graph.Identity.DirectoryManagement

# Set your tenant name
$tenantName = "<TENANT NAME>"

Connect-MgGraph -TenantId $spConnection.TenantId `
    -ClientID $spConnection.ApplicationId `
    -CertificateThumbprint $spConnection.CertificateThumbprint
    Get-MgContext
    








#Disable account
  
		Update-MgUser -UserId $OffUser -AccountEnabled:$false
     Write-Output "Blocking $OffUser from signing in"
    #Get users object ID to sign them and revoke all sessions for browser and application using cmdlet below
   $OffUserObj=(Get-MgUser -UserId $OffUser).Id
   Write-Output $OffUserObj
	 Revoke-MgUserSign -UserId $OffUserObj
    
		
    
    Write-Output "Revoking $OffUser's tokens"
    Write-Output "Removing $OffUser's properties"
    Update-MgUser -CompanyName "X" -UserId $OffUserObj
		Update-MgUser -JobTitle "X" -UserId $OffUserObj
		Update-MgUser -Department "X" -UserId $OffUserObj


##Block user after revoking sessions
    #Set-AzureADUser -ObjectID $OffUser -AccountEnabled $false




# Connect to ExchangeOnline
Connect-ExchangeOnline -CertificateThumbprint $spConnection.CertificateThumbprint `
    -AppId $spConnection.ApplicationID -Organization $tenantName

    



    #Set-CASMailbox $OffUser -OWAEnabled $false -PopEnabled $false -MAPIBlockOutlookRpcHttp $true -IMAPEnabled $false -MAPIEnabled $false
##Convert to Shared Mailbox before removing license
Set-Mailbox -Identity $OffUser -Type Shared 
##Cancel all their organized meetings for the next 2 years (should suffice for everyone I think)
 Write-Output "Converting $OffUser's mailbox to shared and transferring access to specified user or admin"
Remove-CalendarEvents -Confirm:$false -Identity $OffUser -CancelOrganizedMeetings -QueryWindowInDays 120 
Add-MailboxPermission -Identity $OffUser -User $toTransfer -AccessRights FullAccess -InheritanceType All -AutoMapping:$false
##Get username of user to be offboarded, and loop through their licenses to delete them all after turning into shared mailbox and deleting meetingd
 
 ##REMOVE USER FROM DISTRIBUTION LISTS
 Get-DistributionGroup | where { Get-DistributionGroupMember $_.Name |Select WindowsLiveID |`
Where {$_. WindowsLiveID -eq $OffUser }} | ForEach-Object { 
Write-Output "Removing user from Distribution List $($_.PrimarySmtpAddress)"
Remove-DistributionGroupMember -Confirm:$false -Identity $_.PrimarySmtpAddress -Member $OffUser
 
 }
 

 $OffUserNickName= (Get-Mailbox -Identity $OffUser).Name
 $toTransferNickName=(Get-Mailbox -Identity $toTransfer).Name
Get-DistributionGroup  | Where {$_.ManagedBy -contains $OffUserNickName} | ForEach-Object {
 Set-DistributionGroup -Identity $_.PrimarySmtpAddress -ManagedBy @{Add="$toTransferNickName";Remove="$OffUserNickName"}
 }



Write-Output "Removing user $OffUser's licenses"
$userList = Get-MgUser -UserId $OffUser
$MS365BP =  Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'O365_BUSINESS_PREMIUM'
$EmsSku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'EMSPREMIUM'
$MDfE = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'MDATP_XPLAT'
$AudioConference = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'MCOMEETADV'
Set-MgUserLicense -UserId $OffUser -RemoveLicenses @($AudioConference.SkuId) -AddLicenses @{}
Set-MgUserLicense -UserId $OffUser -RemoveLicenses @($MS365BP.SkuId) -AddLicenses @{}
Set-MgUserLicense -UserId $OffUser -RemoveLicenses @($MDfE.SkuId) -AddLicenses @{}
Set-MgUserLicense -UserId $OffUser -RemoveLicenses @($EmsSku.SkuId) -AddLicenses @{}

$OwnedGroups = Get-MgUserOwnedObject -UserId $OffUser | Select-Object -ExpandProperty AdditionalProperties | Where-Object { $_['@odata.type'] -eq '#microsoft.graph.group' }
Get-MgUserMemberOf -UserId $OffUser | ForEach-Object {Remove-MgGroupMemberByRef -GroupId $_.Id -DirectoryObjectId $OffUserObj}
$OwnedGroups.displayName | ForEach-Object {
    $group = Get-MgGroup -Filter "displayName eq '$_'" -Top 1
    Remove-MgGroupOwnerByRef  -GroupId $group.id -DirectoryObjectId $OffUserObj
}

###BLOCK ACCESS TO APPLICATIONS########

##resource id= objectid
$userwithapp= Get-MgUser -UserId $OffUser

 Get-MgUserAppRoleAssignment -UserId $OffUser | Select * | where { $_.PrincipalDisplayName -eq $userwithapp.DisplayName} | ForEach-Object {
 $spo = Get-MgServicePrincipal -ServicePrincipalId $_.ResourceId
 #Write-Output $spo
  $arid = $_.Id
	Write-Output $arid
    Write-Output $spo
$assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $spo.Id | Where {$_.PrincipalDisplayName -eq $userwithapp.DisplayName}
#Write-Output $assignments
$assignments | ForEach-Object {
 #Write-Output  "Output is app role assignment $($_.Id) to ServicePrincipalId $($spo.Id)"
 Remove-MgServicePrincipalAppRoleAssignedTo -AppRoleAssignmentId $arid  -ServicePrincipalId $spo.Id -Confirm:$false
}
 
 }
 
 
 # Get the user and the service principal
