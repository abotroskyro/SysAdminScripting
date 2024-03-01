# Azure Runbooks

## System Managed Identity Runbook
1.	Create Azure Automation Account
2.	Go to Automation Accounts and select the Automation Account in question
3.	On the left hand-side you will see something called “Identity” and an option to use System Managed Identity, turn it on. 

4. Take note of the Object ID, which is known also as the Service Principal ID.
5. The way permissions work in a managed identity, since we are using the MS Graph API, is that we must assign Microsoft Graph permissions to the service principal. 
How does someone assign permissions to the Microsoft Graph API? The Microsoft Graph API itself is a Service Principal, and for another Service Principal, such as the one associated with my Azure System Managed Identity to gain access to the MS Graph API, we need give our Azure System Managed Identity permissions to the MS Graph Service Principal/Resource. 

Now that we’re aware of how we assign permissions to our managed identity/service principal associated with our Azure Automation Account, we need to figure out what permissions our application needs… There’s no need to grant it “Directory.Read.Write.All” permissions if we just need to read specific properties…To find out what permissions your app needs, most MS Graph SDK Powershell modules and MS Graph API documentation will tell you from least to most permissive what permissions your application needs. Make sure to look at application permissions and not delegated permissions. [For example, Get-MgUser](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/get-mguser?view=graph-powershell-1.0) documentation it states that you should call 
```PowerShell
Connect-MgGraph -Scopes User.ReadBasic.All, User.Read.All
```
For the appropriate permissions. From there you can tell what the name of the permission is you need to run the PowerShell MS Graph SDK modules. Generally though, since the PowerShell modules use the HTTP calls underneath for everything, visiting the MS Graph API page instead of the MS Graph PowerShell SDK module will give you a better idea of the [Permissions required for a query](https://learn.microsoft.com/en-us/graph/api/user-get?view=graph-rest-1.0&tabs=http)
 
6. Now that we are aware of a permission name we need, to assign permissions we must use PowerShell (not in the Azure RunBook, but interactively on your computer or on the AZ Cloud Shell…)
```PowerShell
$spID = "59492dec-b25c-4063-9e13-2f7db7ba97e5" #object ID from Step 3
$PermissionName = "User.Read.All" #Permission Name from Step 5
$GraphServicePrincipal = Get-MgServicePrincipal -Filter "startswith(DisplayName,'Microsoft Graph')" | Select-Object -first 1 #We need to get the SP that represents Microsoft Graph
$AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"} #MS Graph SP has a list of possible AppRoles, which correspond to API permissions
#We need to get the AppRole that specifically matches our API permission name. 
New-MgServicePrincipalAppRoleAssignment -AppRoleId $AppRole.Id -ServicePrincipalId $spID -ResourceId $GraphServicePrincipal.Id -PrincipalId $spID #assign the permissions to our Azure Automation SP
$AppRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $spID #This outputs the permissions on our Azure Automation SP to verify the changes
```
7. As said above, we must find the MS Graph SP in Azure. This SP has a list of AppRoles, these AppRoles are API permissions. To assign our Azure Automation SP MS Graph permissions, it needs to be assigned the AppRole of the API permission we desire, and the Azure Automation SP needs the AppRole of “User.Read.All” to the MS Graph SP (assigning a service principal to an app (MS Graph) with AppRoles of (API Permissions)). 

8. To execute a MS Graph API call in an Azure Runbook, do the following:
```PowerShell
Connect-AzAccount -Identity #Identity is intetionally left blank because Azure knows the Automation Account connected to the Runbook
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token
$token = ConvertTo-SecureString "$token" -AsPlainText -Force
Connect-MgGraph -AccessToken $token
```
### Sites.Selected Permissions
1. Assign Sites.Selected Permisssions to your System Managed Identity
```Powershell
$spID = "59492dec-b25c-4063-9e13-2f7db7ba97e5" #object ID of System Managed Identity
$PermissionName = "Sites.Selected" #Desired Permission
$GraphServicePrincipal = Get-MgServicePrincipal -Filter "startswith(DisplayName,'Microsoft Graph')" | Select-Object -first 1 #We need to get the SP that represents Microsoft Graph
$AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"} #MS Graph SP has a list of possible AppRoles, which correspond to API permissions
#We need to get the AppRole that specifically matches our API permission name. 
New-MgServicePrincipalAppRoleAssignment -AppRoleId $AppRole.Id -ServicePrincipalId $spID -ResourceId $GraphServicePrincipal.Id -PrincipalId $spID #assign the permissions to our Azure Automation SP
$AppRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $spID #This outputs the permissions on our Azure Automation SP to verify the changes
```
2. Use the SPO cmdlets to assign your System Managed Identity a specific SPO Site (not inside of a runbook):
```PowerShell
# Add the correct 'Application (client) ID' and 'displayName' for the Managed Identity (MI)
$application = @{
    id = "<MI_APP_ID>"
    displayName = "<MI_Name>"
}

# Add the correct role to grant the Managed Identity (read or write)
$appRole = "write"

# Add the correct SharePoint Online tenant URL and site name
$spoTenant = "<tenantname>.sharepoint.com"
$spoSite  = "IT"

# No need to change anything below
$spoSiteId = $spoTenant + ":/sites/" + $spoSite + ":"

Import-Module Microsoft.Graph.Sites

Connect-MgGraph -Scope Sites.FullControl.All #Sign in interactively to assign Site Permissions to MI. 

New-MgSitePermission -SiteId $spoSiteId -Roles $appRole -GrantedToIdentities @{ Application = $application }
```

