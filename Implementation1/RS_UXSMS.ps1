# Copyright © 2008, Microsoft Corporation. All rights reserved.


. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.uxsmsResolve_progress

# check the Uxsms service startup tpe
$startupType = (Get-WmiObject -query "select * from win32_baseService where Name='Uxsms'").StartMode

#resolver
if($startupType -ne "auto" -and $startupType -ne $null)
{
    (Get-WmiObject -query "select * from win32_baseService where Name='Uxsms'").changeStartMode("automatic") > $null
}

Restart-Service UxSms
WaitFor-ServiceStatus "UXSMS" ([ServiceProcess.ServiceControllerStatus]::Running)