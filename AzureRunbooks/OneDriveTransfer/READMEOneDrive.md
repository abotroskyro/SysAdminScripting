# PowerShell Graph API Automation for Migrating Disabled User Data

This repository contains a PowerShell script that leverages the Microsoft Graph API to automate the migration of disabled users’ OneDrive files to a specified SharePoint site. The script is designed to:

- Retrieve disabled users (excluding any specified exceptions).
- Recursively enumerate files and folders from a user’s OneDrive.
- Recreate folder structures in SharePoint.
- Copy files from OneDrive to SharePoint using two methods:
  - A simple file copy for small files.
  - A chunked upload process for large files (greater than a configurable threshold).

> **Note:** The SharePoint target site and folder IDs are not hardcoded in the script. You will need to provide these values when configuring the script for your environment.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
- [Script Overview](#script-overview)
- [Error Handling & Retries](#error-handling--retries)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Disabled Users Retrieval:** Uses Microsoft Graph to get a list of disabled users while excluding any user specified in a skip list.
- **Recursive File Enumeration:** Traverses OneDrive folder structures recursively, capturing file metadata and folder hierarchies.
- **Folder Creation in SharePoint:** Creates necessary folder structures in SharePoint before copying files.
- **Chunked Upload for Large Files:** Implements a retry mechanism and chunked uploads for large files (approximately 60 MiB per chunk).
- **Graceful Error Handling:** Provides detailed output and retry logic for transient errors such as rate limiting.

---

## Requirements

- **PowerShell 7 or later** (for better module compatibility and error handling)
- **Microsoft Graph PowerShell SDK:**  
  Install with:
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```
- **Az.Accounts Module:**  
  Used for connecting with the system-managed identity.  
  Install with:
  ```powershell
  Install-Module Az.Accounts -Scope CurrentUser
  ```
- **Permissions:**  
  The script requires appropriate permissions for Microsoft Graph to read user details, OneDrive, and SharePoint data. Ensure that your system-managed identity has the required access.

---

## Setup


1. **Configure Target IDs:**  
   Open the script and update the following variables with your target SharePoint site and folder IDs:
   ```powershell
   $targetSiteId = ""
   $targetFolderId = ""
   ```
   > **Security Note:** The script intentionally excludes these IDs from version control. Provide these values in a secure manner (e.g., via environment variables or a secure configuration file) if desired.

2. **Skip List (Optional):**  
   If there are any users you wish to exclude from processing, update the `$skipUsersList` array at the top of the script.

3. **Connect with Managed Identity:**  
   The script uses `Connect-AzAccount -Identity` to authenticate using a system-managed identity. Ensure that your environment is configured to support this authentication method.

---

## Usage

To run the script, open your Azure Runbook and copy the script in


The script will:
- Connect using the system-managed identity.
- Retrieve disabled users from Microsoft Graph.
- Process each disabled user, copying their OneDrive files to the designated SharePoint site.

Monitor the console output for progress and any potential errors. Logging and verbose messages help track the file copy progress, folder creation, and any retry attempts for transient errors.

---

## Script Overview

### Key Functions

- **`Get-DisabledUsers`**  
  Retrieves all disabled users in your tenant while excluding any users provided via the `$skipUsersList`.

- **`Get-SharePointItemsRecursively`**  
  Recursively lists items (files and folders) from a SharePoint drive, useful for checking existing folder structures.

- **`Invoke-MgGraphRequestWithRetry`**  
  Wraps Microsoft Graph API calls with retry logic for handling rate limits (HTTP 429) and temporary service unavailability.

- **`Get-OneDriveItemsRecursively`**  
  Recursively retrieves all files and folders from a user’s OneDrive, building an object that includes file metadata (name, type, size, dates, etc.).

- **`Test-ItemExists`**  
  Checks if a specific item (file or folder) already exists in a target SharePoint folder to avoid duplicates.

- **`Create-FolderPath`**  
  Creates folder hierarchies in the SharePoint document library, ensuring that the destination folder structure matches that of the source OneDrive.

- **`Copy-OneDriveToSharePoint`**  
  Handles the copying of large files using chunked uploads. It downloads file chunks from OneDrive and uploads them to SharePoint using an upload session.

- **`Copy-DisabledUserFiles`**  
  Orchestrates the migration process for a disabled user by:
  - Retrieving the user’s OneDrive items.
  - Creating a corresponding folder in SharePoint.
  - Iterating through files and folders, copying each file to SharePoint.

### Main Execution Flow

1. **Authentication:**  
   Connects to Azure using the system-managed identity and then connects to Microsoft Graph.

2. **User Processing:**  
   Retrieves the list of disabled users and processes each one by calling `Copy-DisabledUserFiles`.

3. **Cleanup:**  
   Disconnects from Microsoft Graph after processing.

---

## Error Handling & Retries

- The function `Invoke-MgGraphRequestWithRetry` implements retry logic when encountering HTTP 429 (Too Many Requests) or service unavailability errors. It extracts the recommended wait time from error messages or headers and retries the request.
- Detailed error messages are logged to help diagnose issues during processing.
- If a file already exists in the target SharePoint location, the script skips it to prevent duplication.

---

