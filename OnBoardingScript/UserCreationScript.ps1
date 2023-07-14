

$spSecret = Get-AutomationVariable -Name AutoUserSecret #Encrypted Variable with client secret


# Get the service principal connection details
$spConnection = Get-AutomationConnection -Name AzureRunAsConnection



    
$MyTenantId=$spConnection.TenantId
$incre = 0
$currentDate="{0:yyyy'-'MM'-'ddTHH':'mm':'ss'Z'}" -f (Get-Date).AddDays(-1)
$date= Get-Date -Format "M/dd/yyyy"
Write-Output $currentDate

# Set your tenant name
$tenantName = "<TENANT NAME>"

$Body = @{
    'tenant' = $spConnection.TenantId
    'client_id' = "<CLIENT ID>"
    'scope' = 'https://graph.microsoft.com/.default'
    'client_secret' = $spSecret
    'grant_type' = 'client_credentials'
}

# Assemble a hashtable for splatting parameters, for readability
# The tenant id is used in the uri of the request as well as the body
$Params = @{
    'Uri' = "https://login.microsoftonline.com/$MyTenantId/oauth2/v2.0/token"
    'Method' = 'Post'
    'Body' = $Body
    'ContentType' = 'application/x-www-form-urlencoded'
}

$AuthResponse = Invoke-RestMethod @Params
$Headers = @{
    'Authorization' = "Bearer $($AuthResponse.access_token)"
}
$GetTop=@()
$SiteId="<SharePoint SiteId"
$SPOFolderId="<SharePoint Folder Id>"
#



    $Resultv4=Invoke-RestMethod  -Uri "https://graph.microsoft.com/v1.0/sites/$SiteId/drive/items/$SPOFolderId/children?`$select=@microsoft.graph.downloadUrl"-Headers $Headers 
  
   $Resultv3= Invoke-RestMethod  -Uri "https://graph.microsoft.com/v1.0/sites/$SiteId/drive/items/$SPOFolderId/children?`$select=name,lastModifiedDateTime,createdBy,id" -Headers $Headers 
    $CheckOrder= Invoke-RestMethod  -Uri "https://graph.microsoft.com/v1.0/sites/$SiteId/drive/items/$SPOFolderId/children" -Headers $Headers
   
     $FileDownloadLinksArray=@($Resultv4.value.'@microsoft.graph.downloadUrl')
  

  $Rebuild=@()
  $AccountRequestsMatrix=@()


     $Resultv3.value | ForEach-Object {
        
        
$AccountRequestsMatrix+= New-Object -TypeName psobject -Property @{FileName="$($_.name)"; fileid="$($_.id)"; creator="$($_.createdBy.user.email)"}
    }
    Write-Output $AccountRequestsMatrix.creator
     Write-Output $AccountRequestsMatrix.count
     for ($i=0; $i -lt $FileDownloadLinksArray.count; $i++) {
       
$AccountRequestsMatrix[$i] | Add-Member -MemberType NoteProperty -Name "dlurl" -Value $FileDownloadLinksArray[$i] -Force

     }
    

   
  
  
    $FinArray=@()
 
   

   
    $AzureTempDir= $env:TEMP
    $i=0;

$MatchingVals= $Resultv3.value | Select id, name


   <#
    1. Get all the files in the Account Request Folder
    2. Loop through each AccountRequest Matrix that contains the download link for the file, the creator, the name of the file, and the id
    3. Import the CSV of each file in the AccountRequest Matrix
    4. Select the objects (csv rows) where the user account requests are for the future
        a. Import all the deferred requests into a separate CSV to be processed at a later date and upload it to the AccountRequests Folder
    5. Select the objects that are current account requests
        a. Create the users using MgGraph
        b. Send an email to the requestor and CC HR on the email
        c. Send an email to the user (if applicable) with their password and CC HR, and CC the account request creator
      
    6. Remove all files from folder and put in ApprovedRequests Folder
    #>


##IMPORTANT, 'DELETE' OBJECTS THAT ARE FROM DEFERRED REQUESTS MADE FROM PREVIOUS ITERATION IF APPLICABLE
#$AccountRequestsMatrix = $AccountRequestsMatrix | where {$_.FileName -notmatch "Deferred"}
Write-Output $AccountRequestsMatrix
Write-Output "Breakpoint, sleeping 15s"
Start-Sleep -s 15







  
    $AccountRequestsMatrix | ForEach-Object {
       # Write-Output $link
$blah=Invoke-WebRequest -Uri "$($_.dlurl)" -OutFile "$AzureTempDir\$($_.FileName)"

++$i

}
$x=0
$AccountRequestsMatrix | ForEach-Object { 
    #$DeferredRowsArray=@()
    "Parsing file called $($_.FileName)"
    $keepname=$_.FileName
 $buildFileName= $_.creator.split("@")
 $FileNameTime=  Get-Date -Format "Hmmss"
 $DeferredCSVFileName="$($buildFileName[0])Deferredrequest$x"
 $DeferredCSVFileName= $DeferredCSVFileName+$FileNameTime

 #Write-Output $DeferredCSVFileName
 $AccountRequestCreator=$_.creator
###skip over CSVs that are for deferred time and put them into new csv to upload to sharepoint
Import-Csv "$AzureTempDir\$($_.FileName)" | Where-Object {(get-date $date) -lt (get-date $_.CreateTime) }|`
ForEach-Object {
    Write-Output $date
    
 #Export-Csv -Path "$env:temp\$($_.DisplayName)DR" -NoTypeInformation 
# Write-Output "$($_)"
 Write-Output "$($_.CreateTime)"
 Write-Output "$($_.UserName), $($_.FirstName), $($_.LastName), $($_.CreateTime)  $($_.PersonalEmail) $($_.Developer)  FUTURE"
 #$AccountRequestsMatrix | ForEach-Object { Where {Import-Csv "$AzureTempDir\$($_.FileName)" | ForEach-Object {Where { $date -ge $_.CreateTime}}} |`
 
 ############################################EXPORT THE OBJECTS TO A CSV AND THEN UPLOAD TO SHAREPOINT FOLDER#########
 if(Test-Path "$AzureTempDir\$DeferredCSVFileName.csv") {
$_ |   Export-Csv -Append "$AzureTempDir\$DeferredCSVFileName.csv"  -Encoding UTF8 -NoTypeInformation  ##pipe entire current object to csv file


 }
 else {
$_ | Export-Csv "$AzureTempDir\$DeferredCSVFileName.csv"  -Encoding UTF8 -NoTypeInformation
 ++$x
 }
 #Get-ChildItem -Path $AzureTempDir 

#PUT /sites/{site-id}/drive/items/{parent-id}:/{filename}:/content
############################################EXPORT THE OBJECTS TO A CSV TO LATER  UPLOAD TO SHAREPOINT FOLDER#########






} ###end for-each object on FUTURE REQUESTS IN CURRENT CSV

$DeferredRequestUpload="$AzureTempDir\$DeferredCSVFileName.csv"
if(Test-Path "$AzureTempDir\$DeferredCSVFileName.csv") {
Write-Output $DeferredRequestUpload
Invoke-RestMethod -Uri  "https://graph.microsoft.com/v1.0/sites/$SiteId/drive/items/$SPOFolderId`:/$DeferredCSVFileName.csv:/content"-Headers $Headers -ContentType 'multipart/form-data' -Method PUT -InFile $DeferredRequestUpload
}
















    Import-Csv "$AzureTempDir\$($_.FileName)" | Where-Object {(get-date $date) -eq (get-date $_.CreateTime)} |`
    ForEach-Object {
        ##Import CSV for parsing, names of files are same as sp
Write-Output "$($_.UserName), $($_.FirstName), $($_.LastName), $($_.CreateTime) $($_.PersonalEmail) $($_.Developer) CURRENT" ##Create user
#Write-Output "All these requests in file $($_.FileName) are equal to  $($_.CreateTime)"
#######################################CREATE USER, ASSIGN LICENSES, ETC.###################
$GetNewUserDomain=$_.UserName.split("@")
$GetNewUserDomain=$GetNewUserDomain[1]
$UserCompany=""
if ($GetNewUserDomain -like "company1*"){
    $UserCompany="Comapny 1"
}
if ($GetNewUserDomain -like "company2*") {
    $UserCompany="Company 2"
}
if ($GetNewUserDomain -like "company3*") {
    $UserCompany="Comapny 3"
}
if ($GetNewUserDomain -like "company4*") {
	$UserCompany="Company 4"
}
if ($GetNewUserDomain -like "parentco") {
	$UserCompany="Parent Company"
}

Write-Output $UserCompany
Connect-MgGraph -TenantId $spConnection.TenantId `
    -ClientID $spConnection.ApplicationId `
    -CertificateThumbprint $spConnection.CertificateThumbprint
    Get-MgContext

Select-MgProfile -Name "beta"
#New-MgUserAuthenticationPhoneMethod -UserId $_.UserName -phoneType "mobile" -phoneNumber $_.MobilePhone
$PasswordProfile = @{}
$PasswordProfile["Password"]= ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?.;,._".ToCharArray() | Get-random -Count 50) -join ""
$UserTempPass= $PasswordProfile["Password"]
Write-Output "Password is $UserTempPass for $($_.UserName)"
$PasswordProfile["ForceChangePasswordNextSignInWithMfa"]=$true
$NewUserNickName= @()
$NewUserNickName=$_.UserName.split("@")
$NewUserNickName=$NewUserNickName[0]
Select-MgProfile -Name beta
#Get-MgProfile | Write-Output
$NewUserDetails=$null
#$NewUserDetails=New-MgUser -DisplayName $_.DisplayName -MailNickName $NewUserNickName -CompanyName $UserCompany -PasswordProfile $PasswordProfile -AccountEnabled -UserPrincipalName $_.UserName #-Authentication $PhoneMethods
if($_.Developer -eq "yes") {
  $NewUserDetails=New-MgUser -DisplayName $_.DisplayName -MailNickName $NewUserNickName -CompanyName $UserCompany -PasswordProfile $PasswordProfile -AccountEnabled -UserPrincipalName $_.UserName -JobTitle "Developer"  
}
else {
    $NewUserDetails=New-MgUser -DisplayName $_.DisplayName -MailNickName $NewUserNickName -CompanyName $UserCompany -PasswordProfile $PasswordProfile -AccountEnabled -UserPrincipalName $_.UserName
}
Write-Output "$($_.UserName) is a developer? $($_.Developer)"
#Write-Output $NewUserDetails.UserPrincipalName
Write-Output "$($_.UserName) created, sleeping for 30 seconds"
Start-Sleep -s 30

Write-Output $GetUserID
Write-Output "$($_.MobilePhone)"
$ParsePhone= "+" + $_.MobilePhone
Write-Output $ParsePhone
$userauthtest=New-MgUserAuthenticationPhoneMethod -UserId $NewUserDetails.UserPrincipalName -phoneType "mobile" -phoneNumber $ParsePhone
Write-Output $userauthtest
Get-MgUserAuthenticationPhoneMethod -UserId $NewUserDetails.UserPrincipalName | Write-Output
Update-MgUser -UserId $NewUserDetails.UserPrincipalName -UsageLocation "US"
Set-MgUserLicense -UserId $NewUserDetails.UserPrincipalName -addlicenses @{SkuId = 'b05e124f-c7cc-45a0-a6aa-8cf78c946968'} -RemoveLicenses @() | Write-Output
Set-MgUserLicense -UserId $NewUserDetails.UserPrincipalName -addlicenses @{SkuId = 'f245ecc8-75af-4f8e-b61f-27d8114de5f3'} -RemoveLicenses @()  | Write-Output
#Update-MgUser -UserId $NewUserDetails.UserPrincipalName -UsageLocation "US"
#>

#TODO 9-23-2021
#1. Get SKU ID for EMS E5, Business Standard
#2. Figure out password dilemma
#3. Test user creation using what if and see if I can use that to validate the correctness of the info in the CSV?

#b05e124f-c7cc-45a0-a6aa-8cf78c946968 ems e5 sku id
#
Write-Output "Notifying Creator and CCing HR"
$NotifyTo=""
###TODO 9-28
#AFTER CONFIRMING EVERYTHING WORKS, CHANGE THE TORECIPIENT TO A VARIABLE AND SEND IT TO CREATOR AND CC HR
#Maybe get rid of extra CC email address field?
$TestUserBody =
@"
{
"message" : {
"subject": "User Account Creation Notification for $($_.UserName)",
"body" : {
"contentType":"Text",
"content": "This is an email confirming the account creation of user $($_.DisplayName) with email address $($_.UserName) and phone number $($_.MobilePhone)"
},
"toRecipients": [{"emailAddress" : { "address" : "<IT ADMIN EMAIL>"}}],
"ccRecipients": [{"emailAddress":  {"address": "<HR EMAIL>}}]},
"saveToSentItems": "true"
}
"@


$FromAddress="<ADMIN OR DAEMON UPN"
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$FromAddress/sendMail" -Body $TestUserBody -Method POST -ContentType 'application/json' -Headers $Headers
















#############################################################################################

###################################NOTIFY NEW USER OF ACCOUNT CREATION AND SEND THEM PASSWORD################











############################################################################################################



######################################NOTIFY NEW USER ###########################
Write-Output "Sending welcome email to $($_.DisplayName)"
     $htmlhead="<html>
     <style>
      BODY{font-family: Arial; font-size: 10pt;}
	H1{font-size: 22px;}
	H2{font-size: 18px; padding-top: 10px;}
	H3{font-size: 16px; padding-top: 8px;}
    </style>"
#Header for the message
$HtmlBody = "<body>
     <h1>Welcome to Our Company</h1>
     <p><strong>Generated:</strong> $(Get-Date -Format g)</p>  
     <h2><u>We're Pleased to Have You Here</u></h2>"

# Other lines
Write-Output "Sending welcome email to $($_.DisplayName)"
      $MsgSubject = "Welcome $($_.DisplayName)!"
      $htmlHeaderUser = "<h2> Read Below for your login information </h2>"
      $htmlline1 = "<p><b>Welcome to Office 365</b></p>"
      $htmlline2 = "<p>Your username is $($_.UserName)</p>"
      $htmlline3 = "<p>Your temporary password is $UserTempPass</p>"
      
      $htmlline4 = "<p>You can open Office Online by clicking <a href=https://www.office.com/?auth=2>here</a> </p>"
      $htmlbody = $htmlheaderUser + $htmlline1 + $htmlline2 + $htmlline3 + $htmlline4 + "<p>"
      $HtmlMsg = "</body></html>" + $htmlhead + $HtmlBody
  
      $CCArray="<HR EMAIL ADDRESS>"
$ConfirmMailBody = 
@"
{
"message" : {
"subject": "$MsgSubject",
"body" : {
"contentType":"html",
"content": "$HtmlMsg"
},
"toRecipients": [{"emailAddress" : { "address" : "$($_.PersonalEmail)" }}]
},
"saveToSentItems": "true"
}
"@









$Confirm2=""



Start-Sleep -s 30
$FromAddress="<ADMIN UPN>"
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$FromAddress/sendMail" -Body $ConfirmMailBody -Method POST -ContentType 'application/json' -Headers $Headers
    

######################################MESSAGE NEW USER AT AZURE AD EMAIL WITH ATLASSIAN LINK###############
Write-Output "Sending Atlassian onboarding email to $($_.DisplayName)"
      $MsgSubject = "Welcome $($_.DisplayName)!"
      $htmlHeaderUser = "<h2> Guide to VPN, Gitlab, Company Calendar and more!</h2>"
      #$htmlline1 = "<p><b>Guide to VPN, Gitlab, and more!</b></p>"
      $htmlline1 = "<p>The link to our guide can be found on Atlassian, you are granted access automatically to Atlassian upon clicking the link below</p>"
      $htmlline2 = "<p>On-Boarding Link: <a href=https://company.atlassian.net/l/c/5vCW4654854WXSg>here</a> </p>"
      $htmlbody = $htmlheaderUser + $htmlline1 + $htmlline2 + "<p>"
      $HtmlMsg = "</body></html>" + $htmlhead + $HtmlBody
  
      $CCArray="<HR EMAIL ADDRESS>"
$OnBoardEmailBody = 
@"
{
"message" : {
"subject": "$MsgSubject",
"body" : {
"contentType":"html",
"content": "$HtmlMsg"
},
"toRecipients": [{"emailAddress" : { "address" : "$($NewUserDetails.UserPrincipalName)" }}]
},
"ccRecipients": [{"emailAddress":  {"address": "<HR EMAIL ADDRESS>"}}]
},
"saveToSentItems": "true"
}
"@

Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$FromAddress/sendMail" -Body $OnBoardEmailBody -Method POST -ContentType 'application/json' -Headers $Headers


#########################################Add Groups, Calendars, etc. here#######################################
Connect-AzureAD -TenantId $spConnection.TenantId `
    -ApplicationId $spConnection.ApplicationId `
    -CertificateThumbprint $spConnection.CertificateThumbprint

$DesiredGroups = @()
$DesiredGroups= $_.Groups.split(";")
foreach ($group in $DesiredGroups) {
$GetGroupIDs=(Get-AzureADGroup -SearchString "$group").ObjectId
Add-AzureADGroupMember -ObjectId $GetGroupIDs -RefObjectId $NewUserDetails.id





}























#########################################Add Groups, Calendars, etc. here#######################################


#######################################################################################################

  }#END FOR OBJECT  CURRENT REQUESTS









#/sites/{site-id}/drive/items/{parent-id}:/{filename}:/content






####move future requests from azure temp directory to the AccountRequests Folder to be picked up at later date


   } #######end outer for each object for ALL REQUESTS










   #############This block below moves ALL files, regardless of account creation date, as deferred requests will simply
   #be remade as a separate and single file for each csv with future requests, 
#these list of files are files that were grabbed in the beginning of the program 

#to prevent uploads from the several lines above from being moved to the 'finished' folder


$AccountRequestsMatrix | ForEach-Object { ##get info of sharepoint files to iterate over and move CLEAN UP)
$MoveFolderBody= @{ ##setup body to send to graph endpoint to move folder
    'name' = "$($_.FileName)" #name of the sharepoint file to move 
  'parentReference'= @{id='<SPO FOLDER ID>'} #sharepoint file id of the folder for finished requests
  
} 
$MoveFolderBody = $MoveFolderBody | ConvertTo-Json #convert to json so graph api can parse
#Write-Output $MoveFolderBody
#-ContentType 'application/json'
$Resultv6=Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/sites/$SiteId/drive/items/$($_.fileid)" -Method PATCH -Body $MoveFolderBody -Headers $Headers -ContentType 'application/json'
} #^^ issue patch request with specified body and patch /sites/{site-id}/drive/items/{item-id}













