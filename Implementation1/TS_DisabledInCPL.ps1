# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceID)

. .\CL_RegSnapin.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

$dll = "AudioDiagnosticSnapIn.dll"
$namespace = "AudioDiagCommandSnapin"
[bool]$result = $false

Write-DiagProgress -activity $localizationString.disabledInCPL_progress

try {

    RegSnapin $dll $namespace
    $device = Get-AudioDevice -id "$deviceID"

    $device | Select-Object -Property @{Name=$localizationString.state;Expression={Get-DeviceStateName ($_.State)}},@{Name=$localizationString.statusCode;Expression={$_.State}},@{Name=$localizationString.helpLink;Expression={"http://msdn.microsoft.com/en-us/library/aa363230(VS.85).aspx"}} | convertto-xml | Update-DiagReport -id AudioDeviceDisabled -name $localizationString.disabledInCPL_name -description $localizationString.disabledInCPL_description -Verbosity Informational -rid "RC_DisabledInCPL"

    $result = -not(($device.State -band 2) -eq 2)
} finally {
    UnregSnapin $dll $namespace
}

if(-not($result))
{
    Update-DiagRootCause -id "RC_DisabledInCPL" -Detected $true -parameter @{'DeviceID'=$deviceID}
} else {
    Update-DiagRootCause -id "RC_DisabledInCPL" -Detected $false -parameter @{'DeviceID'=$deviceID}
}

return $result
