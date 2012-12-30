# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceType, $deviceID)

. .\CL_RegSnapin.ps1
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

$dll = "AudioDiagnosticSnapIn.dll"
$namespace = "AudioDiagCommandSnapin"
[bool]$result = $false

Write-DiagProgress -activity $localizationString.lowVolume_progress

try {

    RegSnapin $dll $namespace
    $device = Get-AudioDevice -id "$deviceID"
    if($device.State -eq 1)
    {
        $result = ($device.MasterVolume -gt 20)
    }

    $device | Select-Object -Property @{Name=$localizationString.currentVolume;Expression={[string]($_.MasterVolume) + "%"}} | ConvertTo-Xml | Update-DiagReport -id CurrentVolumeLevel -name $localizationString.CurrentVolumeLevel_name -description (($localizationString.CurrentVolumeLevel_description) -f (Get-DeviceName $deviceType)) -Verbosity Informational -rid "RC_LowVolume"

} finally {
    UnregSnapin $dll $namespace
}

if(-not($result))
{
    Update-DiagRootCause -id "RC_LowVolume" -Detected $true -parameter @{'DeviceType'=$deviceType; 'DeviceID'=$deviceID}
} else {
    Update-DiagRootCause -id "RC_LowVolume" -Detected $false -parameter @{'DeviceType'=$deviceType; 'DeviceID'=$deviceID}
}

return $result
