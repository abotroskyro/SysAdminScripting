Start-Transcript -Path "C:\temp\win32logs.txt" -NoClobber
# Policy binary files should be named as {GUID}.cip for multiple policy format files (where {GUID} = <PolicyId> from the Policy XML)
$ScriptRootDir = $(pwd).Path

$PolicyCIP = "{959A0F15-8985-4551-A208-5FFE9EDB3A70}.cip"
$DestinationFolder = $env:windir+"\System32\CodeIntegrity\CiPolicies\Active\"



#$RefreshPolicyTool = "$ScriptRootDir\RefreshPolicy.exe"
$CIToolLoc="$ScriptRootDir\CiTool.exe"
Write-Output $RefreshPolicyTool
Write-Output $DestinationFolder

Copy-Item -Path "$PolicyCIP" -Destination C:\Windows\sysnative\CodeIntegrity\CiPolicies\Active -Force

#& $RefreshPolicyTool
& C:\Windows\sysnative\CiTool.exe --update-policy $PolicyCIP
C:\Windows\sysnative\CiTool.exe --refresh

Stop-Transcript
