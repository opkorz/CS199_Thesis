# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceID)

. .\CL_RegSnapin.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

$dll = "AudioDiagnosticSnapIn.dll"
$namespace = "AudioDiagCommandSnapin"
[bool]$result = $false

Write-DiagProgress -activity $localizationString.mute_progress

try {

    RegSnapin $dll $namespace
    $device = Get-AudioDevice -id "$deviceID"
    if($device.State -eq 1)
    {
        $result = -not($device.Mute)
    }
} finally {
    UnregSnapin $dll $namespace
}

if(-not($result))
{
    Update-DiagRootCause -id "RC_Mute" -detected $true -parameter @{'DeviceID'=$deviceID}
} else {
    Update-DiagRootCause -id "RC_Mute" -detected $false -parameter @{'DeviceID'=$deviceID}
}

return $result
