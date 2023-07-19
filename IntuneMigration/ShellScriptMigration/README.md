# ShellScript Migration
## shellscript_export.ps1
This script will take all Shell Scripts (Bash/ZSH scripts in Intune) and output each one to a separate JSON file that can be uploaded to another (or the same if you really want) tenant using the import script describd below. This script copies the content of the scripts which are Base64 encoded. You can verify their contents by decoding them in PowerShell (or whatever other language) as you wish
## devicemanscript_import.ps1
This script will take the exported JSON files from shellscript_export.ps1, and will upload them to Intune using the MS Graph API. 