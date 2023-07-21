$CIP_Path = "{AF3BCDF0-6E07-498E-B927-7429E1015D9C}.cip"
$DestinationFolder = $env:windir+"\System32\CodeIntegrity\CIPolicies\Active\"
Remove-Item -Path "$DestinationFolder$CIP_Path"

