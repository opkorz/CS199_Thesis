# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceID)

. .\CL_RegSnapin.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

$dll = "AudioDiagnosticSnapIn.dll"
$namespace = "AudioDiagCommandSnapin"

Write-DiagProgress -activity $localizationString.unmute_progress

try
{
    RegSnapin $dll $namespace

    if((Get-AudioDevice -id "$deviceID").Mute -eq $true)
    {
        (Get-AudioDevice -id "$deviceID").Mute = $false
    }
}
finally
{
    UnregSnapin $dll $namespace
}
