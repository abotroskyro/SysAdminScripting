# IntuneConfigProfileMigration
## config_profile_export.ps1
This script exports Device Configuration Profiles (not ADMX or Settings Catalog). It outputs all the profiles to their own JSON file, which can then be used with config_profile_import.ps1
## config_profile_import.ps1
This script takes the exported JSON and sends it in the body of a request to the MS Graph API to upload the config profiles to Intune. 