# Roster Publishing Script
1. This script is designed to export a list of active users, their licenses, UPNs, and PersonalEmails (which is a Custom Security Attribute) to an excel spreadsheet in the specified SharePoint site and folder.
2. This script is designed to run in an Azure Runbook with a System Managed Identity. Automation Account authentication is set to be deprecated in several months and System Managed Identities are the (most secure) way forward.
3. After setting up the Custom Security Attribute and the System Managed Identity, you can run the script.
## Custom Security Attribute Setup
1. [Custom Security Attribute](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/custom-security-attributes-add?tabs=ms-powershell#add-an-attribute-set)
2. [Add an Attribute Set](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/custom-security-attributes-add#add-a-custom-security-attribute)
3.   Login to PowerShell (not on a runbook) and change the status of the attribute to Available. Notice the name is 'AttributeSetName_AttributeName':
```PowerShell
Select-MgProfile "beta"
Get-MgDirectoryCustomSecurityAttributeDefinition
Connect-MgGraph -Scopes User.Read.All, Organization.Read.All,CustomSecAttributeDefinition.ReadWrite.All
Select-MgProfile "beta"
Get-MgDirectoryCustomSecurityAttributeDefinition #Change status to available to it can be used.
$params = @{`
Status = "Available"`
}
$customSecurityAttributeDefinitionId = "RosterData_PersonalEmail" #This will correspind to whatever you setup in steps 1 and 2, but must be in this format.
Update-MgDirectoryCustomSecurityAttributeDefinition -CustomSecurityAttributeDefinitionId $customSecurityAttributeDefinitionId -BodyParameter $params
Import-Module Microsoft.Graph.Applications
```
4. To update the Custom Security Attribute with a value:
```PowerShell
Import-Module Microsoft.Graph.Applications

$params = @{
	CustomSecurityAttributes = @{
		RosterData = @{
			"@odata.type" = "#Microsoft.DirectoryServices.CustomSecurityAttributeValue"
			PersonalEmail = "<value goes here>"
		}
	}
}

Update-MgUser -UserId "<UPN>" -BodyParameter $params
```
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

