# PowerShellScript Migration
## devicemanscripts_export.ps1
This script will take all DeviceManagement (PowerShell scripts in Intune) and output each one to a separate JSON file that can be uploaded to another (or the same if you really want) tenant. This script does copy the content of the scripts which are Base64 encoded. You can verify their contents by decoding them in PowerShell (or whatever other language) as you wish
## devicemanscripts_import.ps1
This script will take the exported JSON files from devicemanscripts_export.ps1, and will upload them to Intune using the MS Graph API. 