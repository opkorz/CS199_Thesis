# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceType, $deviceID)

. .\CL_RegSnapin.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

$dll = "AudioDiagnosticSnapIn.dll"
$namespace = "AudioDiagCommandSnapin"
[bool]$result = $true
Write-DiagProgress -activity $localizationString.notDefault_progress

try {
    RegSnapin $dll $namespace
    $device = Get-AudioDevice -id $deviceID

    Parse-List $deviceType | Foreach-Object {
        if(-not([String]::IsNullOrEmpty($_)))
        {
            if(-not($device.IsDefaultAudioDevice($_)))
            {
                $result = $false
            }
        }
    }
} finally {
    UnregSnapin $dll $namespace
}

if(-not($result))
{
    Update-DiagRootCause -id "RC_NotDefault" -detected $true -parameter @{'DeviceType'=$deviceType; 'DeviceID'=$deviceID}
} else {
    Update-DiagRootCause -id "RC_NotDefault" -detected $false -parameter @{'DeviceType'=$deviceType; 'DeviceID'=$deviceID}
}

return $result
