# JiraGitlabDeployment.py
## What It Does
1. This python script will track Gitlab releases that are intended to run on a Gitlab Runner when a MR is merging into main/master (in our case this was 'dev) and then will report the deployment to Jira to be used in Cycle Time Reports. So this script requires that you have Jira Connect working with your self managed Gitlab instance already.
2. This script needs commit merge history to be preserved (found in Gitlab project settings)
3. As it stands now, the current Gitlab to Jira connector will only track deployments that occurr during MR pipelines, rather than the actual merge of a branch into main/master, which is a more common workflow for deployments. The Gitlab issue that goes into great detail about what people's issues are with Gitlab<->Jira Connector [Here](https://gitlab.com/gitlab-org/gitlab/-/issues/300031)
## What It Needs to Work
1. Gitlab for Jira Cloud App
2. A Jira Admin needs to setup an OAuth2 App to communicate to Gitlab. Admin->Apps->OAuth Credentials with:
URL: ```<gitlab_instance_url>/-/jira_connect/oauth_callbacks```
Give the app deployment permissions (Check Deployment box under Permissions)
3. Release Environments setup in Gitlab
4. The following in your CI/CD
 ```yaml
###PRIVATE TOKEN IS ENVIRONMENT VARIABLE THAT IS API KEY
deploy_prod:
  stage: deploy
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_REF_NAME == "main"'
  before_script:
  - apt-get update
  - apt-get install -y jq
  - which jq
  script: 
    #- print (CI_MERGE_REQUEST_SOURCE_BRANCH_NAME)
    - MR_BRANCH_LAST_COMMIT_SHA=$(curl -s --header "PRIVATE-TOKEN:$PRIVATE_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/repository/commits/$CI_COMMIT_SHA" | jq -r '.parent_ids | del(.[] | select(. == "'$CI_COMMIT_BEFORE_SHA'")) | .[-1]')

    - echo $MR_BRANCH_LAST_COMMIT_SHA
    - MR_BRANCH_NAME=$(curl -s --header "PRIVATE-TOKEN:$PRIVATE_TOKEN" "$CI_API_V4_URL/projects/$CI_PROJECT_ID/repository/commits/$MR_BRANCH_LAST_COMMIT_SHA/merge_requests" | jq -r '.[0].source_branch')
    - export MR_BRANCH_NAME
    - export MR_BRNCH_LAST_COMMIT_SHA
    - echo $MR_BRANCH_NAME
    - echo $MR_BRANCH_LAST_COMMIT_SHA
    - python3 JiraGitlabDeployment.py
  ```
5. The above will give you the name of the branch BEFORE you merge into main, so that you could track it to the original issue in Jira that went from branch to deployment in a Cycle Time Report and use it's name in the release/deployment. It will then export these variables to help the python script link Jira and Gitlab deployments together

  
