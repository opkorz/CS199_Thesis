# Copyright © 2008, Microsoft Corporation. All rights reserved.

. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.transparencyResolve_progress

if(-not(Test-Path HKCU:\Software\microsoft\windows\dwm))
{
    Set-Item HKCU:\Software\Microsoft\Windows\DWM
}

if((Get-ItemProperty "HKCU:\software\Microsoft\Windows\DWM" "ColorizationOpaqueBlend") -eq $null)
{
    New-ItemProperty -Path "HKCU:\software\Microsoft\Windows\DWM" -Name "ColorizationOpaqueBlend" -PropertyType DWORD -Value 0
}

Set-ItemProperty -Path HKCU:\Software\microsoft\windows\dwm -Name ColorizationOpaqueBlend -Value 0

Restart-Service UXSMS
WaitFor-ServiceStatus "UXSMS" ([ServiceProcess.ServiceControllerStatus]::Running)