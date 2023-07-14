## Requirements

This script is designed to use with an Azure Runbook and an Azure Automation Account Your service principal MUST be given app permissions to use the MS Graph SDK.
1. In the case of this script, the Azure Automation Account IS the Service Principal. Therefore, going to the Azure portal->Registered Applications->Click on the app (look for a name similar to your Automation Account)->API Permissions->Add a Permission->Microsoft Graph.
2. This script also uses a series of Exchange Online cmdlets to do things such as converting a mailbox to a shared mailbox and giving a manager access, and also for cancelling all the meetings in which they are the organizers. To enable app-based authentication for Exchange Online, follow the steps at this link [set-up-app-only-authentication](https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps#set-up-app-only-authentication)
3. This script takes two parameters, the first 'OffUser' which is the UPN of the user to off-board and is required. The second parameter, requires the object ID of the user you want to transfer the Mailbox to, such as a manager or supervisor. In my implementation, this defaulted to a specific managers object ID.                                                                                                                                                                   
## What it Does
1. Revokes all sign in sessions, and then disables the user's account.
2. Removes them from all groups (except for Dynamic, which update periodically)
3. Removes them from all Distribution Lists (except Dynamic ones)
4. Cancels all their meetings for the next 2 years.
5. Removes all their licenses.
6. Converts their mailbox to a shared mailbox and gives a specified manager full access to it.
7. Removes them from all applications.
