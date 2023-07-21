# SysAdminScripts
## GitlabOffBoardingScript
A shell script that removes a user from Gitlab once their MS365 account has been disabled.
## JiraCycleTimeReport
A Python script that enables Jira to properly track deployments and releases from Gitlab
## OnBoardingScript
A PowerShell script that takes a CSV from a SharePoint Online folder and creates the user based on the information in the CSV and sends email notifications to the appropriate persons.
## RosterPublishing
A PowerShell script designed to run in an Azure Runbook with a System Identity. The script gets a list of current active users, their licenses, name, email, and personalEmail.
## UserOffBoarding
A PowerShell script that off-boards a user (removes them groups, distribution lists, applications, converts mailbox to a shared mailbox, etc.)
## IntuneMigration
This folder contains 4 sets of scripts. These are traditionally supposed to be used in the event of a tenant migration, where you would very much like to NOT copy all your profiles manually. Specifically, the sets of scripts will import and export the following from Intune:
1. Shell Scripts
2. PowerShell Scripts
3. Endpoint Security Profiles
4. Intune Config Profiles (those not ES,ADMX, or SettingsCatalog)

All of these scripts use the MS Graph API, and were used with interactive login. Most if not all of these scripts can be modified for app/service principal based authentication. 

## MacOS
This folder contains a series of scripts used for Application Whitelisting/Blacklisting and sending logs to Intune. 
## WDAConAVD
This folder contains a series of files and scripts that enable and enforce a Windows Defender Application Control policy on multi-session enteprise Azure Virtual Desktops (which cannot receive custom WDAC policies as other devices such as a physical laptop can)
