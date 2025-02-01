# Function to get items recursively
$skipUsersList = @(
)

function Get-DisabledUsers {
    param (
        [string[]]$SkipUsers
    )
    try {
        $filter = "accountEnabled eq false"
        $disabledUsers = @()
        $users = Get-MgUser -Filter $filter -All
        
        foreach ($user in $users) {
            if ($user.UserPrincipalName -notin $SkipUsers) {
                $disabledUsers += $user.UserPrincipalName
            }
        }
        return $disabledUsers
    }
    catch {
        Write-Error "Error getting disabled users: $_"
        throw
    }
}


function Get-SharePointItemsRecursively {
    param (
        [string]$SiteId,
        [string]$FolderId,
        [string]$Path = "",
        [array]$Results = @()
    )
    
    $uri = "v1.0/sites/$SiteId/drive/items/$FolderId/children"
    $items = Invoke-MgGraphRequestWithRetry -Method GET -Uri $uri
    
    foreach ($item in $items.value) {
        $currentPath = if ($Path) { "$Path/$($item.name)" } else { $item.name }
        
        $Results += [PSCustomObject]@{
            FileName = $currentPath
            FileType = if ($item.folder) { "Folder" } else { $item.file.mimeType }
            Id = $item.id
        }
        
        if ($item.folder) {
            $Results = Get-SharePointItemsRecursively -SiteId $SiteId -FolderId $item.id -Path $currentPath -Results $Results
        }
    }
    
    return $Results
}


function Invoke-MgGraphRequestWithRetry {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Method,
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        [Parameter(Mandatory=$false)]
        [object]$Body,
        [Parameter(Mandatory=$false)]
        [hashtable]$Headers,
        [Parameter(Mandatory=$false)]
        [string]$OutputType
    )

    $attempt = 0
    
    while ($true) {
        try {
            $params = @{
                Method = $Method
                Uri = $Uri
            }
            if ($Body) { $params['Body'] = $Body }
            if ($Headers) { $params['Headers'] = $Headers }
            if ($OutputType) { $params['OutputType'] = $OutputType }

            $response = Invoke-MgGraphRequest @params
            return $response
        }
        catch {
            # Convert error object to string to check for error details
            $errorDetails = $_.Exception.Message
            $retryAfter = $null

            # Try to parse error message for retryAfterSeconds
            if ($errorDetails -match '"retryAfterSeconds":(\d+)') {
                $retryAfter = [int]$Matches[1]
            }
            # Also check response headers for Retry-After
            elseif ($_.Exception.Response.Headers['Retry-After']) {
                $retryAfter = [int]$_.Exception.Response.Headers['Retry-After']
            }

            # Check for various retry conditions
            if ($_.Exception.Response.StatusCode -eq 429 -or 
                $errorDetails -match "serviceNotAvailable" -or 
                $errorDetails -match "TooManyRequests") {
                
                $attempt++
                
                if (-not $retryAfter) {
                    $retryAfter = 10  # Default to 10 seconds if no retry time specified
                }
                
                Write-Warning "Rate limit or service unavailable. Attempt $attempt. Waiting $retryAfter seconds before retry..."
                Start-Sleep -Seconds $retryAfter
                
                # Continue the loop to retry
                continue
            }
            else {
                Write-Error "Non-retriable error occurred: $_"
                throw
            }
        }
    }
}


function Get-OneDriveItemsRecursively {
    param (
        [string]$DriveId,
        [string]$ItemId = "root",
        [string]$Path = "",
        [array]$Results = @(),
        [string]$UserEmail
    )
    
    $uri = if ($ItemId -eq "root") {
        "v1.0/drives/$DriveId/root/children"
    } else {
        "v1.0/drives/$DriveId/items/$ItemId/children"
    }
    
    $items = Invoke-MgGraphRequestWithRetry -Method GET -Uri $uri
    
    foreach ($item in $items.value) {
        $currentPath = if ($Path) { "$Path/$($item.name)" } else { $item.name }
        
        $Results += [PSCustomObject]@{
            UserEmail = $UserEmail
            FileName = $currentPath
            FileType = if ($item.folder) { "Folder" } else { $item.file.mimeType }
            Size = if ($item.size) { [math]::Round($item.size/1MB, 2).ToString() + " MB" } else { "N/A" }
            LastModified = $item.lastModifiedDateTime
            Created = $item.createdDateTime
            Id = $item.id  # Add the item ID to the results
        }
        
        # If it's a folder, recursively get its contents
        if ($item.folder) {
            $Results = Get-OneDriveItemsRecursively -DriveId $DriveId -ItemId $item.id -Path $currentPath -Results $Results -UserEmail $UserEmail
        }
    }
    
    return $Results
}



function Test-ItemExists {
    param (
        [string]$TargetSiteId,
        [string]$ParentFolderId,
        [string]$ItemName
    )
    
    try {
        # Clean up the ParentFolderId to ensure it's just the ID
        $ParentFolderId = $ParentFolderId.Trim()
        
        $checkUri = "v1.0/sites/$TargetSiteId/drive/items/$ParentFolderId/children"
        Write-Verbose "Checking existence with URI: $checkUri"
        
        $existingItems = Invoke-MgGraphRequestWithRetry -Method GET -Uri $checkUri
        return ($existingItems.value | Where-Object { $_.name -eq $ItemName }) -ne $null
    }
    catch {
        Write-Error "Error checking if item exists (URI: $checkUri): $_"
        return $false
    }
}










function Create-FolderPath {
    param (
        [string]$TargetSiteId,
        [string]$ParentFolderId,
        [string]$FolderPath
    )
    
    # Normalize path separators and trim any leading/trailing separators
    $FolderPath = $FolderPath.Trim('/\')
    
    # Split on both forward and backward slashes
    $folders = [regex]::Split($FolderPath, '/|\\') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    
    # Store just the ID
    [string]$currentParentId = $ParentFolderId.Trim()
    
    foreach ($folder in $folders) {
        Write-Host "Processing folder: $folder"
        
        # Get current folder contents
        $existingFolderUri = "v1.0/sites/$TargetSiteId/drive/items/$currentParentId/children"
        
        try {
            $existingFolders = Invoke-MgGraphRequestWithRetry -Method GET -Uri $existingFolderUri
            $existingFolder = $existingFolders.value | Where-Object { $_.name -eq $folder }
            
            if ($existingFolder) {
                $currentParentId = $existingFolder.id
                Write-Host "Found existing folder: $folder"
            }
            else {
                $createFolderUri = "v1.0/sites/$TargetSiteId/drive/items/$currentParentId/children"
                $folderBody = @{
                    "name" = $folder
                    "folder" = @{}
                    "@microsoft.graph.conflictBehavior" = "rename"
                } | ConvertTo-Json
                
                try {
                    $newFolder = Invoke-MgGraphRequestWithRetry -Method POST -Uri $createFolderUri -Body $folderBody
                    $currentParentId = $newFolder.id
                    Write-Host "Created folder: $folder"
                }
                catch {
                    Write-Error "Error creating folder '$folder': $_"
                    throw
                }
            }
        }
        catch {
            Write-Error "Error accessing folder '$folder': $_"
            throw
        }
    }
    
    return $currentParentId
}




function Copy-OneDriveToSharePoint {
    param (
        [string]$DriveId,
        [string]$ItemId,
        [string]$TargetSiteId,
        [string]$TargetFolderId,
        [string]$SourceFileName,
        [string]$TargetFileName
    )

    # Check if file already exists
    if (Test-ItemExists -TargetSiteId $TargetSiteId -ParentFolderId $TargetFolderId -ItemName $TargetFileName) {
        Write-Output "File already exists, skipping: $TargetFileName"
        return
    }

    # Constants for upload chunks
    [long]$CHUNK_SIZE = 327680 * 180  # ~60 MiB (multiple of 320 KiB)
    
    try {
        # 1. Get the source file download URL
        $sourceUri = "v1.0/drives/$DriveId/items/$ItemId/content"
        Write-Output "Getting source file download URL..."
        
        # Get file metadata first to know the size
        $fileMetadata = Invoke-MgGraphRequestWithRetry -Method GET -Uri "v1.0/drives/$DriveId/items/$ItemId"
        [long]$fileSize = $fileMetadata.size
        
        # 2. Create upload session in target SharePoint
        Write-Output "Creating upload session in SharePoint..."
        $uploadUri = "v1.0/sites/$TargetSiteId/drive/items/${TargetFolderId}:/$($TargetFileName):/createUploadSession"
        $uploadSession = Invoke-MgGraphRequestWithRetry -Method POST -Uri $uploadUri
        
        if (-not $uploadSession.uploadUrl) {
            throw "Failed to get upload URL from session"
        }

        # 3. Download and upload in chunks
        [long]$offset = 0
        $context = Get-MgContext
        
        while ($offset -lt $fileSize) {
            [long]$chunkEnd = [Math]::Min($offset + $CHUNK_SIZE - 1, $fileSize - 1)
            [long]$contentLength = $chunkEnd - $offset + 1
            
            # Download chunk
            $downloadHeaders = @{
                "Range" = "bytes=$offset-$chunkEnd"
            }
            
            Write-Output "Downloading chunk: bytes $offset-$chunkEnd of $fileSize"
            # Changed OutputType to HttpResponseMessage
            $chunk = Invoke-MgGraphRequest -Method GET -Uri $sourceUri -Headers $downloadHeaders -OutputType HttpResponseMessage
            $chunkContent = $chunk.Content.ReadAsStreamAsync().Result
            
            # Prepare chunk for upload
            $uploadHeaders = @{
                'Authorization' = "Bearer $($context.AccessToken)"
                'Content-Range' = "bytes $offset-$chunkEnd/$fileSize"
            }
            
            Write-Output "Uploading chunk: $($uploadHeaders['Content-Range'])"
            
            # Upload chunk
            $uploadResponse = Invoke-RestMethod `
                -Uri $uploadSession.uploadUrl `
                -Method Put `
                -Headers $uploadHeaders `
                -Body $chunkContent `
                -ContentType 'application/octet-stream'
            
            $offset = $chunkEnd + 1
            
            # Check if this was the last chunk
            if ($offset -ge $fileSize) {
                Write-Output "Upload completed successfully"
                return $uploadResponse
            }
        }
    }
    catch {
        Write-Error "Error in Copy-OneDriveToSharePoint: $_"
        throw
    }
}

function Copy-DisabledUserFiles {
    param (
        [string]$TargetSiteId,
        [string]$TargetFolderId,
        [string]$UserEmail,
        [int]$FileSizeThresholdMB = 10
    )
    
    try {
        # Get user
        $user = Get-MgUser -Filter "userPrincipalName eq '$UserEmail'"
        Write-Output "Processing $UserEmail..."
        
        # Get user's OneDrive
        $oneDrive = Invoke-MgGraphRequest -Method GET -Uri "v1.0/users/$($user.Id)/drive"
        
        if (-not $oneDrive) {
            Write-Warning "No OneDrive found for $($user.UserPrincipalName)"
            return
        }
        
        # Create a folder in SharePoint for this user
        $userFolderName = $user.UserPrincipalName.Replace("@", "_at_")
        $userFolderId = $null

        # Check if user folder exists and get existing files
        $existingFolders = Invoke-MgGraphRequest -Method GET -Uri "v1.0/sites/$TargetSiteId/drive/items/$TargetFolderId/children"
        $userFolder = $existingFolders.value | Where-Object { $_.name -eq $userFolderName }
        
        if ($userFolder) {
            $userFolderId = $userFolder.id
            Write-Output "Found existing user folder: $userFolderName"
            
            # Get existing files in SharePoint
            Write-Output "Getting existing files in SharePoint..."
            $existingFiles = Get-SharePointItemsRecursively -SiteId $TargetSiteId -FolderId $userFolderId
            $existingFilePaths = @{}
            foreach ($file in $existingFiles) {
                $existingFilePaths[$file.FileName] = $true
            }
        }
        else {
            Write-Output "Creating new user folder: $userFolderName"
            $createFolderUri = "v1.0/sites/$TargetSiteId/drive/items/$TargetFolderId/children"
            $folderBody = @{
                "name" = $userFolderName
                "folder" = @{}
            } | ConvertTo-Json
            
            $userFolder = Invoke-MgGraphRequest -Method POST -Uri $createFolderUri -Body $folderBody
            $userFolderId = $userFolder.id
            $existingFilePaths = @{}
        }
        
        # Get all items recursively from OneDrive
        Write-Output "Getting OneDrive files..."
        $oneDriveItems = Get-OneDriveItemsRecursively -DriveId $oneDrive.Id -UserEmail $user.UserPrincipalName
        
        # Filter out already existing files
        $itemsToCopy = $oneDriveItems | Where-Object { -not $existingFilePaths[$_.FileName] }
        
        Write-Output "Found $($itemsToCopy.Count) new files to copy out of $($oneDriveItems.Count) total files"
        
        foreach ($item in $itemsToCopy) {
            try {
                if ($item.FileType -eq "Folder") {
                    # Create empty folder
                    $folderPath = $item.FileName
                    Create-FolderPath -TargetSiteId $TargetSiteId -ParentFolderId $userFolderId -FolderPath $folderPath
                }
                else {
                    # Get the folder path without the filename
                    $folderPath = Split-Path $item.FileName
                    $filename = Split-Path $item.FileName -Leaf
                    
                    if (![string]::IsNullOrEmpty($folderPath)) {
                        # Create folder structure and get the ID of the deepest folder
                        $targetFolderId = Create-FolderPath -TargetSiteId $TargetSiteId -ParentFolderId $userFolderId -FolderPath $folderPath
                    }
                    else {
                        $targetFolderId = $userFolderId
                    }
                    
                    $size = [decimal]($item.Size -replace " MB", "")
                    
                    if ($size -gt $FileSizeThresholdMB) {
                        Write-Output "Copying large file: $filename (Size: $size MB)"
                        Copy-OneDriveToSharePoint `
                            -DriveId $oneDrive.Id `
                            -ItemId $item.Id `
                            -TargetSiteId $TargetSiteId `
                            -TargetFolderId $targetFolderId `
                            -SourceFileName $item.FileName `
                            -TargetFileName $filename
                    }
else {
    Write-Output "Copying small file: $filename (Size: $size MB)"
    
    try {
        # Get the download URL from the item metadata first
        $sourceMetadataUri = "v1.0/drives/$($oneDrive.Id)/items/$($item.Id)"
        $fileMetadata = Invoke-MgGraphRequest -Method GET -Uri $sourceMetadataUri
        
        if (-not $fileMetadata.'@microsoft.graph.downloadUrl') {
            throw "Could not get download URL for file"
        }
        
        # Use the download URL to get content
        $downloadUrl = $fileMetadata.'@microsoft.graph.downloadUrl'
        $targetUri = "v1.0/sites/$TargetSiteId/drive/items/$targetFolderId`:/$filename`:/content"
        
        Write-Verbose "Download URL obtained"
        Write-Verbose "Target URI: $targetUri"
        
        # Get the content using Invoke-RestMethod instead
        $contentBytes = Invoke-RestMethod -Uri $downloadUrl -Method Get -ContentType "application/octet-stream"
        
        if ($null -eq $contentBytes) {
            throw "Received null content from download URL"
        }
        
        # Upload the content
        Write-Verbose "Uploading file content..."
        $uploadResponse = Invoke-MgGraphRequest -Method PUT -Uri $targetUri -Body $contentBytes
        Write-Output "Successfully copied: $filename"
    }
    catch {
        Write-Error "Failed to copy file $filename"
        Write-Error "Error details: $_"
        Write-Error "Item ID: $($item.Id)"
        throw
    }
}
                }
            }
            catch {
                Write-Error "Failed to copy file $($item.FileName): $_"
                Write-Error "Details - DriveId: $($oneDrive.Id), ItemId: $($item.Id)"
                continue
            }
        }
    }
    catch {
        Write-Error "Error in Copy-DisabledUserFiles: $_"
        throw
    }
}

# Your existing variables stay in the script
$targetSiteId = ""
$targetFolderId = ""

# First, connect using the system-managed identity
try {
    Write-Output "Connecting using system-managed identity..."
    Connect-AzAccount -Identity
    $graphToken = (Get-AzAccessToken -ResourceTypeName MSGraph).Token
    $graphTokenSecure = ConvertTo-SecureString $graphToken -AsPlainText -Force
    Connect-MgGraph -AccessToken $graphTokenSecure
    
    Write-Output "Getting list of disabled users..."
    $disabledUsers = Get-DisabledUsers -SkipUsers $skipUsersList
    
    Write-Output "Found $($disabledUsers.Count) disabled users to process"
    
    foreach ($userEmail in $disabledUsers) {
        Write-Output "Processing user: $userEmail"
        try {
            Copy-DisabledUserFiles -UserEmail $userEmail -TargetSiteId $targetSiteId -TargetFolderId $targetFolderId
        }
        catch {
            Write-Error "Failed to process user $userEmail : $_"
            continue
        }
    }
}
catch {
    Write-Error "Failed during user processing: $_"
    throw
}
finally {
    Disconnect-MgGraph
}