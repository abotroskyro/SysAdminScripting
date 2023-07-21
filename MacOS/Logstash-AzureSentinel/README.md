# LogStash, FileBeat and Azure Sentinel
This project is designed to automate, and showcase the possibilities of centralized logging in an Intune environment with MacOS. Azure Sentinel has a Filebeat and LogStash connector that will send all logs sent to a specified directory, to Azure Sentinel as a Custom Table to be ingested. 
# Pre-Installation
## The Custom Configuration Profiles:
### MDM Setup
1. The three configuration profiles listed below show be assigned via MDM (Intune in this case) BEFORE the script has ran.
2. Intune places custom configuration profiles 'Managed Preferences' (MCX), these files when deployed through MDM, even if deleted, will appear back after a reboot or sign out. These will be used in the script described later.
3. The plists themselves are designed to continuously enable or enforce the components necessary for LogStash+FileBeat to work.

## com.elasticsearch.filebeat.plist
This enforces the filbeat config that will be installed later. This allows filebeat to 'recover' in the event that a component has died, or gotten 'stuck'
## com.org.logstash.plist
This plist enables/enforces the Azure Sentinel config required for logs to be sent 
## all_install.sh
1. This less than graceful script, will install LogStash, FileBeat, and the LogStash Azure Sentinel Connector from start to finish. (Enabling system modules, required configurations). Rather than deal with Intune's fickle and sometimes slow to act pkg deployment, I used heredocs to put the entirety of the necessary configs inside the script, which are then outputted to the appropriate file. I have some more experience with PKGs now, so I probably would opt for a cleaner way of using just a pkg with the files bundled...but it worked!

# Post Installation
## The Custom Configuration Profiles:

## com.getprivate.mobileconfig
This mobileconfig is designed to allow the Mac's logging system to actually out the username tied to a specific activity rather than showing <private>, which is the default MacOS behavior. 

## com.logcollect.plist
This plist uses the Mac OS' native logging tool to stream logs for failed logins to a specified directory on the Mac. It runs in the background constantly, so that you can ensure logins are being tracked. The directory the logs are sent to, are the same ones specified in the LogStash configuration file. These logins then end up in Azure Sentinel, ready to be digested and analyzed. 