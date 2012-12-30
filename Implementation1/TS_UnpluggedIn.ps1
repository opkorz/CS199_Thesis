# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceType, $deviceID)

. .\CL_RegSnapin.ps1
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

$dll = "AudioDiagnosticSnapIn.dll"
$namespace = "AudioDiagCommandSnapin"
$result = $false

Write-DiagProgress -activity $localizationString.unpluggedIn_progress

try {
    RegSnapin $dll $namespace
    $device = Get-AudioDevice -id "$deviceID"

    $result = -not(($device.State -band 8) -eq 8)
} finally {
    UnregSnapin $dll $namespace
}

[string]$deviceTypeName = Get-DeviceTypeName $deviceType

if(-not($result))
{
    Update-DiagRootCause -id "RC_UnpluggedIn" -detected $true -parameter @{'DeviceType'=$deviceTypeName;'DeviceID'=$deviceID}
} else {
    Update-DiagRootCause -id "RC_UnpluggedIn" -detected $false -parameter @{'DeviceType'=$deviceTypeName;'DeviceID'=$deviceID}
}


return $result
