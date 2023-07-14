import jwt
import time
import requests
import hashlib
import json
import webbrowser
import base64
import atlassian_jwt
import os
import subprocess




#Acquire access token from Jira using Jira OAuth2 credentials.This is required because only OAuth2 access tokens are allowed to authenticate and use the Jira Build and Deployments APIs

url = 'https://api.atlassian.com/oauth/token'
headers = {'Content-Type': 'application/json'}
payload = {
    "audience": "api.atlassian.com",
    "grant_type": "client_credentials",
    "client_id": "<client id>", #CLIENT ID OF OAUTH2 credentials in Jira, should be in environment variable and masked.
    "client_secret": "<client secret>" #Client secret for OAuth2 credentials, this should be a masked environment variable, should not be in plaintext. Only including it here so you can add it to Qtoken. 
}


response = requests.post(url, headers=headers, data=json.dumps(payload))

data = response.json()
jira_token = data['access_token'] #store access token to be used in subsequent Jira Deployment API calls


#Get all the Gitlab Runner predefined variables we need loaded into a variable in python.
CI_API_V4_URL = os.environ.get('CI_API_V4_URL')
CI_PROJECT_ID = os.environ.get('CI_PROJECT_ID')
CI_COMMIT_SHA = os.environ.get('CI_COMMIT_SHA')
CI_COMMIT_BEFORE_SHA = os.environ.get('CI_COMMIT_BEFORE_SHA')
MR_BRANCH_LAST_COMMIT_SHA = os.environ.get('MR_BRANCH_LAST_COMMIT_SHA')
MR_BRANCH_NAME = os.environ.get('MR_BRANCH_NAME')
CI_JOB_URL = os.environ.get('CI_JOB_URL')
CI_PIPELINE_URL = os.environ.get('CI_PIPELINE_URL')
CI_PIPELINE_CREATED_AT = os.environ.get('CI_PIPELINE_CREATED_AT')
CI_PIPELINE_ID = os.environ.get('CI_PIPELINE_ID')

print (CI_API_V4_URL)
print (CI_PROJECT_ID)




"""
Branch issue key is taken from one of the 2 jq calls in the CI/CD which sets the 'MR_BRANCH_NAME' variable. This is based off of Jira's naming convention when you click on "Create a branch in Gitlab" which is generally <IssueKey>-<IssueNumber>-name-of-issue-in-jira. For example:
"IN-30-set-host-firewalls-configuration" The line below grabs everything before the second "-" so in this example, branch_issue_key = IN-30

"""

branch_issue_key = MR_BRANCH_NAME[:MR_BRANCH_NAME.find("-", MR_BRANCH_NAME.find("-") + 1)]

print(branch_issue_key)


url = 'https://api.atlassian.com/jira/deployments/0.1/cloud/<atlassian cloud ID>/bulk'

#Set the required authentication headers and insert the access token for the Atlassian API we acquired with our OAuth2 credentials..
auth_headers = {
  
  "Authorization": f"Bearer {jira_token}",
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}



payload = {
  "properties": {
    "accountId": "<Atlassian Account Id>",
    "projectId": "18" #This is the ID of the project in JIRA, mine was 18.
  },
  "deployments": [
    {
      "deploymentSequenceNumber": 1, #Ideally, this should be a variable that's updated globally, because if you have multiple deployments and updates for one ISSUE you want it to keep track of these two fields. This may not be a problem for Qtoken. 
      "updateSequenceNumber": 1,
      "issueKeys": [
        branch_issue_key #insert branch issue key to associate deployment with the Jira Issue
      ],
      
      "displayName": "tEST", #this should be something better than what I have here, how you choose to name it, is entirely up to you. 
      "url": CI_JOB_URL, #gitlab predeifned environment variable that was imported into python...
      "description": "The bits are being transferred",
      "lastUpdated": CI_PIPELINE_CREATED_AT,
      "label": "Release 2023-03-01_08-47-bc2421a", #SHOULD USE VARIABLE HERE, JUST PLACEHOLDER
      "state": "Successful", #this might be a problem, it's always set to success...this can be left as is but you may have to only run the python script if a deployment is successful...this could be done in the "After Script" stage or through a conditional based on an exit code...
      "pipeline": {
        "id": CI_PIPELINE_ID,
        "displayName": f"Test Test{branch_issue_key}", #You change the displayname, but I do recommend keeping the branch issue key in the name. 
        "url": CI_PIPELINE_URL
      },
      "environment": {
        "id": "11", #This is the ID of the environment in GITLAB. You can find this by going to an already created environment (Project->Deployments->Environments and click on the name).The resulting URL will have the project ID. Example: https://gitlab.optimusprime.ai/virgilsystems/demos/terraformalt/-/environments/11 so id = 11
        "displayName": "terraformalt/DevProd", #this needs to change for your project, it's just <project name>/<environment name>
        "type": "production" #Don't change this, otherwise deployments won't show up in Cycle Time Reports
      },
      "schemaVersion": "1.0" #Required. 
    }
  ],
  "providerMetadata": {
    "product": "Gitlab 15.8" #Totally optional. 
  }
} 
print(json.dumps(payload))

#Send the json body above
response = requests.post(
    url,
    headers=auth_headers,
    data=json.dumps(payload)
)


print(json.dumps(response)) #PRINT JSON RESPONSE OF API CALL TO JIRA. 




