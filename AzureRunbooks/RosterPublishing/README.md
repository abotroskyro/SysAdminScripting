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


