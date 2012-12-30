# Copyright © 2008, Microsoft Corporation. All rights reserved.


Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.audioDeviceDriver_progress

try {
    $devices = Get-WmiObject Win32_SoundDevice

} catch {
    $_
}

if ($devices -eq $null) {
    Update-DiagRootCause -id "RC_AudioDevice" -Detected $true -parameter @{"DEVICEID" = "ScanOnly"}
    return $false
}

foreach ($device in $devices) {
    if ($device.ConfigManagerErrorCode -ne 0) {
        $deviceID = $device.PNPDeviceID.Replace("&", "&amp;");
        Update-DiagRootcause -id "RC_AudioDevice" -Detected $true -parameter @{"DEVICEID" = $deviceID}

        return $false
    }
}

Update-DiagRootcause -id "RC_AudioDevice" -Detected $false
return $true
