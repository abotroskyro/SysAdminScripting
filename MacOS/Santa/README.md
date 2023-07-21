# Santa macOS

## Deploying Santa via MDM
1.	Apply .mobileconfig profiles for it to work, these 4 files are:
2.	com.google.santa.example.mobileconfig (Config settings, blacklisting,whitelisting, enforcement mode) 
3.	notificationsettings.santa.example.mobileconfig (Notification delivery system)
4.	tcc.configuration-profile-policy.santa.example.mobileconfig (Trusting santa and allowing it full disk access so that it can block all applications in scope) 
5.	system-extension-policy.santa.example.mobileconfig (System Extension permissions in addition to the above to not require user interaction)

The .mobileconfigs from the Santa Github Repo were not modified, EXCEPT for com.google.santa.example.mobileconfig the original is below and underneath that are my modifications/additions
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>PayloadContent</key>
			<dict>
				<key>com.google.santa</key>
				<dict>
					<key>Forced</key>
					<array>
						<dict>
							<key>mcx_preference_settings</key>
							<dict>
								<key>BannedBlockMessage</key>
								<string>This application has been banned</string>
								<key>ClientMode</key>
								<integer>1</integer>
								<key>EnablePageZeroProtection</key>
								<false/>
								<key>EventDetailText</key>
								<string>Open sync server</string>
								<key>EventDetailURL</key>
								<string>https://sync-server-hostname/blockables/%file_sha%</string>
								<key>FileChangesRegex</key>
								<string>^/(?!(?:private/tmp|Library/(?:Caches|Managed Installs/Logs|(?:Managed )?Preferences))/)</string>
								<key>MachineIDKey</key>
								<string>MachineUUID</string>
								<key>MachineIDPlist</key>
								<string>/Library/Preferences/com.company.machine-mapping.plist</string>
								<key>MachineOwnerKey</key>
								<string>Owner</string>
								<key>MachineOwnerPlist</key>
								<string>/Library/Preferences/com.company.machine-mapping.plist</string>
								<key>ModeNotificationLockdown</key>
								<string>Entering Lockdown mode</string>
								<key>ModeNotificationMonitor</key>
								<string>Entering Monitor mode&lt;br/&gt;Please be careful!</string>
								<key>MoreInfoURL</key>
								<string>https://sync-server-hostname/moreinfo</string>
								<key>SyncBaseURL</key>
								<string>https://sync-server-hostname/api/santa/</string>
								<key>UnknownBlockMessage</key>
								<string>This application has been blocked from executing.</string>
							</dict>
						</dict>
					</array>
				</dict>
			</dict>
			<key>PayloadEnabled</key>
			<true/>
			<key>PayloadIdentifier</key>
			<string>0342c558-a101-4a08-a0b9-40cc00039ea5</string>
			<key>PayloadType</key>
			<string>com.apple.ManagedClient.preferences</string>
			<key>PayloadUUID</key>
			<string>0342c558-a101-4a08-a0b9-40cc00039ea5</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>PayloadDescription</key>
	<string>com.google.santa</string>
	<key>PayloadDisplayName</key>
	<string>com.google.santa</string>
	<key>PayloadIdentifier</key>
	<string>com.google.santa</string>
	<key>PayloadOrganization</key>
	<string></string>
	<key>PayloadRemovalDisallowed</key>
	<true/>
	<key>PayloadScope</key>
	<string>System</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>9020fb2d-cab3-420f-9268-acca4868bdd0</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
```
### Modifications
```xml
                                <key>ClientMode</key>
								<integer>2</integer>
                                <key>AllowedPathRegex</key>
                                <string>/*</string>
```
## santablacklist.zsh

1. This script can either run on a schedule, or as post install script after the installation of the Santa PKG. these two commands add all JetBrains and Kaspersky binaries, and applications as blacklisted, the full commands are as follows:
```zsh
/usr/local/bin/santactl rule --block --identifier "2ZEFAR8TH3" --teamid #JetBrains TeamID

/usr/local/bin/santactl rule --block --identifier "2Y8XE5CQ94" –teamid #Kaspersky TeamID
```

 
 
### Santa Block Rules
To build block rules, a powerful way to do so is the TeamID, the TeamID is a 10 digit alphanumeric string that identifies the developer of an application. PyCharm, and CLion all have the same TeamID associated with their applications/binaries because both are developed by JetBrains which is associated with a TeamID. To get the TeamID of a Binary:
To add applications with simple rules (i.e. ones that don’t involve regex) to block by TeamID, which is essentially like the app Publisher, first get the path of the application, and run 
```zsh
santactl fileinfo "/Volumes/Pycharm CE/PyCharm CE.app"
```
Or more generally:
```zsh
santactl fileinfo “<full-path-to-app>”
```
You can confirm the rule is in place, by the output from the command above, which should return “Added rule for TeamID: <TEAMID>”
