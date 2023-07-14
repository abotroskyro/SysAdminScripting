# GitlabOffBoarding.sh
1. This uses a Service Principal/App Based Authentication to the MS Graph API to check for disabled Accounts (User.Read.All) in Azure AD and disables them in Gitlab.

Traditionally, SCIM would take care of this. However, due to Gitlab being on-premise and being behind a Firewall this wasn't an option. This can cause excess license seats and overages if not kept in check.

So this script runs on the Gitlab machine itself as a cronjob, since that traffic will be allowed to flow through the Firewall and to Azure AD's public endpoints, and then back to the Gitlab instance behind a Firewall.

2. This script requires a Gitlab API key with the approrpiate permissions AND an access token for the MS Graph API.
