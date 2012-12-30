# Copyright © 2008, Microsoft Corporation. All rights reserved.


# Load Common Library
. .\CL_RunDiagnosticScript.ps1
. .\CL_RegSnapin.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

function GetId($deviceInfo=$("No device info is specified"))
{
    return ($deviceInfo | Select-Object DeviceId).DeviceId
}

function GetAdapterName($deviceInfo=$("No device info is specified"))
{
    return ($deviceInfo | Select-Object AdapterName).AdapterName
}

function GetDes($deviceInfo=$("No device info is specified"))
{
    return ($deviceInfo | Select-Object DeviceDes).DeviceDes
}

function GetJackInfo($deviceInfo=$("No device info is specified"))
{
    return ($deviceInfo | Select-Object JackInfo).JackInfo
}

function GetDeviceType()
{
    [string]$type = Get-DiagInput -id "IT_GetDeviceType"

    Parse-List $type | Select-Object @{Name=$localizationString.deviceType;Expression={$_}} | ConvertTo-Xml | Update-DiagReport -id AudioDevice -name $localizationString.AudioDevice_name -description $localizationString.AudioDevice_Description -Verbosity Informational


    return $type
}

function ConvertTo-JackLoc([int]$index = $(throw "No index is specified"))
{
    $result = $localizationString.jackLocInfo  + " "
    switch ($index) {
        1 {$result += $localizationString.rear; break}
        2 {$result += $localizationString.front; break}
        3 {$result += $localizationString.left; break}
        4 {$result += $localizationString.right; break}
        5 {$result += $localizationString.top; break}
        6 {$result += $localizationString.bottom; break}
        7 {$result += $localizationString.rearslide; break}
        8 {$result += $localizationString.risercard; break}
        9 {$result += $localizationString.insidelid; break}
        10 {$result += $localizationString.drivebay; break}
        11 {$result += $localizationString.HDMIconnector; break}
        12 {$result += $localizationString.Outsidelid; break}
        13 {$result += $localizationString.ATAPIconnector; break}
        default {$result = $localizationString.noJackInfoAvailable; break}
    }

    return $result
}

function GetDeviceId([string]$type=$("No type is specified"))
{
    [string]$id = $null
    [string]$dll = "AudioDiagnosticSnapIn.dll"
    [string]$namespace = "AudioDiagCommandSnapin"
    [int]$count = 0
    [string]$defaultFlag = "<Default />"
    $choices = New-Object System.Collections.ArrayList

    try {
        RegSnapin $dll $namespace

        [Array]$device = $null
        Parse-List $type | Foreach-Object {
           if(-not([String]::IsNullOrEmpty($type)))
           {
               $device += Get-AudioDevice -typename "$_"
           }
        }

        $count = $device.Length

        if($count -eq 1)
        {
            $id = GetId $device
        }
        elseif ($count -gt 1)
        {
            foreach($item in $device)
            {
                $deviceDes = GetDes $item
                $deviceId = GetId $item
                $jackInfo = GetJackInfo $item
                $adapterName = GetAdapterName $item
                $jackloc = ConvertTo-JackLoc $jackInfo
                $name = "$deviceDes - $adapterName`r`n`r`n$jackloc.`r`n"

                $choices += @{"Name"="$name"; "Description"="$name"; "Value"="$deviceId"; "ExtensionPoint"=""}
            }

            ($choices[0]).ExtensionPoint = $defaultFlag

            $id = Get-DiagInput -id "IT_GetCertainDevice" -Choice $choices
        }
    } finally {
        UnregSnapin $dll $namespace
    }

    return $id
}

# function to check whether current package is running on remote session
function CheckRemoteSession {
    [string]$sourceCode = @"
using System;
using System.Runtime.InteropServices;

namespace Microsoft.Windows.Diagnosis {
    public static class RemoteManager {
        private const int SM_REMOTESESSION = 0x1000;

        [DllImport("User32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetSystemMetrics(int Index);

        public static bool Remote() {
            return (0 != GetSystemMetrics(SM_REMOTESESSION));
        }
    }
}
"@
    $type = Add-Type -TypeDefinition $sourceCode -PassThru

    return $type::Remote()
}

# Main diagnostic flow
if(CheckRemoteSession) {
    Get-DiagInput -ID "IT_RunOnRemoteSession"
    return
}

[string]$regLogName = "Registry log.reg"
reg.exe export "HKLM\Software\Microsoft\Windows\CurrentVersion\MMDevices" $regLogName /y
if((0 -eq $LASTEXITCODE) -and (Test-Path $regLogName)) {
    Update-DiagReport -file $regLogName -id InstalledAudioDevice -name $localizationString.installedAudioDevice_name -description $localizationString.installedAudioDevice_description -Verbosity Informational
}

if((RunDiagnosticScript {& .\TS_AudioDeviceDriver.ps1}) -eq $false)
{
    return
}

if((RunDiagnosticScript {& .\TS_AudioService.ps1}) -eq $false)
{
    return
}

# Get audio device type
[string]$audioDeviceType = GetDeviceType

# Get audio device ID
[string]$audioDeviceID = GetDeviceId $audioDeviceType
if([String]::IsNullOrEmpty($audioDeviceID))
{
    return
}

if((RunDiagnosticScript {& .\TS_DisabledInCPL.ps1 $audioDeviceID}) -eq $false)
{
    return
}

if((RunDiagnosticScript {& .\TS_UnpluggedIn.ps1 $audioDeviceType $audioDeviceID}) -eq $false)
{
    return
}

RunDiagnosticScript {& .\TS_NotDefault.ps1 $audioDeviceType $audioDeviceID}

RunDiagnosticScript {& .\TS_Mute.ps1 $audioDeviceID}

RunDiagnosticScript {& .\TS_LowVolume.ps1 $audioDeviceType $audioDeviceID}
