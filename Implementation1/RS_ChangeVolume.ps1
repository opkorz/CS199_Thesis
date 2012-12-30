# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceType, $deviceID)

. .\CL_RegSnapin.ps1
. .\CL_Invocation.ps1
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

$dll = "AudioDiagnosticSnapIn.dll"
$namespace = "AudioDiagCommandSnapin"

try
{
    RegSnapin $dll $namespace
    $device = Get-AudioDevice -id "$deviceID"
    [string]$id = $device.EndpointId

    if($deviceType -eq "speakers/headphones/Headset Earphone")
    {
        $input = Get-DiagInput -id "IT_ChangeVolumeSH" -Parameter @{'ID' = $id}
    }

    if($deviceType -eq "microphone/Headset microphone")
    {
        $input = Get-DiagInput -id "IT_ChangeVolumeM"  -Parameter @{'ID' = $id}
    }

    $device | Select-Object -Property @{Name=$localizationString.modifiedVolume;Expression={[string]($_.MasterVolume) + "%"}} | ConvertTo-Xml | Update-DiagReport -id CurrentVolumeLevel -name $localizationString.CurrentVolumeLevel_name -description (($localizationString.ModifiedVolumeLevel_description) -f (Get-DeviceName $deviceType)) -Verbosity Informational
}
finally
{
    UnregSnapin $dll $namespace
}
