# EndpointSecurityProfileMigration
## esp_export.ps1
This script exports Endpoint Security Profiles from Intune. Each profile is exported to a JSON file, which can then be fed to esp_import.ps1. 
## esp_import.ps1
This script takes the exported JSON and sends it in the body of a request to the MS Graph API to upload the Endpoint Security Profiles to Intune