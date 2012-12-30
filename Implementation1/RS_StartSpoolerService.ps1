# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Start the spooler service and set the mode as automatic
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
. .\CL_Utility.ps1
Write-DiagProgress -activity $localizationString.progress_rs_startSpoolerService

[string]$startupType = (Get-WmiObject -query "select * from win32_baseService where Name='Spooler'").StartMode


if($startupType -ne "auto")
{
    (Get-WmiObject -query "select * from win32_baseService where Name='Spooler'").changeStartMode("automatic")
}

Start-Service Spooler
WaitFor-ServiceStatus "Spooler" ([ServiceProcess.ServiceControllerStatus]::Running)