#!/bin/bash

#To access the microsoft graph api NOT on behalf of a user you must first register an app in Azure AD
#Then you create a client secret in the App Registration portal and use it to get an access token
#You also need to consent as an admin to permissions that are granted to the app I used User.Read.All and Directory.Read.All, these are the least permissive options
#The boilerplate for this request can be found here: https://docs.microsoft.com/en-us/graph/auth-v2-service
getToken=$(curl -d 'client_id'='<Registered applications client ID>' \
-d 'scope'='https://graph.microsoft.com/.default' \
-d 'client_secret'='<Client Secret Generated in App Registration>' \
-d 'grant_type'='client_credentials' \
 'https://login.microsoftonline.com/<Azure AD Tenant ID>/oauth2/v2.0/token')
justToken=$(echo $getToken | jq -r '.access_token')
#use jq (json query) to get just the access token so that it can be passed as a variable when it is used to authenticate when making MS Graph API calls. 
echo $justToken
test=$(curl -v -X GET "https://graph.microsoft.com/v1.0/users?\$select=id,userPrincipalName,DisplayName,accountEnabled&\$filter=accountEnabled%20eq%20false" -H "Authorization: Bearer $justToken" -H 'Content-Type: application/json' | jq -r  '.value[].displayName')


#?\$select=id,userPrincipalName,DisplayName,accountEnabled&\$filter=accountEnabled%20eq%20false

	#https://docs.microsoft.com/en-us/graph/query-parameters
	#the line above gets the specified fields from all users,so their name, email, and if their account is enabled
	# I use an odata filter to filter the objects I selected from all possible user fields to get only where accountEnabled=false
	# This will output all objects that have accountEnabled=false
	# the jq field will then get from the available subset of objects that meet accountEnabled=false and get ONLY the DisplayName field
	# The reason I've done display names and not UPNs is to avoid issues with any possible email change, since people don't usually change their names.. thought it was solid
	#Because the syntax when using HTTPS actually has "accountEnabled eq false" with white space, we need to use %20 to represent the space properly

#I put the curl command in a variable so that I could loop over the names of the users that have their accountsDisabled in Azure AD
#the jq command gets the value field, and the member property I requested called displayName

IFS=$'\n' 
#because jq ends up separating the output with a newline, I need to use the bash separator that splits the output on the newline character
#this ends up putting each displayName into it's own variable looking like 'Aidan Kehoe \n' and the next has 'Atif Ali \n' etc.


	for jqo in $(echo "$test"); do #iterate over output from curl and jq command by echo'ing it
		upns=$(echo "$jqo" | tr -d '\n') #'Aidan  \n' and the next has 'Atif \n', I use tr do trim off the newline so it's just their name in a string
		upns=$(echo "$upns" | sed 's/ /%20/g') #You'll note that the names have spaces in between the first and last name, so I use sed to replace all spaces with '%20'
		echo "$upns"
		gitlab_id=$(curl --header "PRIVATE-TOKEN: <Gitlab Personal Access Token>" "https://<gitlab URL>/api/v4/users?search=${upns}" | jq '.[] .id')
		#We use a PAT to authenticate to the Gitlab API and then we do a search query on the users using their first and last name and extract their GITLAB USER ID
		for ids in $(echo "$gitlab_id"); do #iterate over the jq and curl output like the previous for loop did
			git_id=$(echo "$ids" | tr -d '\n') #gitlab_id is of form '30\n20\n' etc so we trim off the newline to get only the ID to pass it to the API request below
				curl -X POST --header "PRIVATE-TOKEN: <Gitlab Personal Access Token>" "https://<gitlab URL>/api/v4/users/${git_id}/block"
				#send a post request to block the user based on the gitlab id
				#at this point, anyone who has their id in this pool of ids has their account disabled in Azure AD and should be blocked here as well. 
				curl -X GET --header "PRIVATE-TOKEN: <Gitlab Personal Access Token>" "https://<gitlab URL>/api/v4/users/${git_id}"
				#print info of the user to verify their state is indeed "blocked" on the output
		done
		#end the inner for loop
	done
	#end the outer for loop
unset #good practice to unset the IFS rule

###Improvement: Could skip users that are blocked in Azure AD but don't have access to Gitlab, currently it doesn't generate errors, so that would just for cleanliness
