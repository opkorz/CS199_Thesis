# Copyright © 2008, Microsoft Corporation. All rights reserved.


Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData
Write-DiagProgress -activity $localizationString.audioServiceStart_progress

# Function to wait for expected service status
function WaitFor-ServiceStatus([string]$serviceName=$(throw "No service name is specified"), [ServiceProcess.ServiceControllerStatus]$serviceStatus=$(throw "No service status is specified")) {
    [ServiceProcess.ServiceController]$sc = New-Object "ServiceProcess.ServiceController" $serviceName
    [TimeSpan]$timeOut = New-Object TimeSpan(0,0,0,5,0)
    $sc.WaitForStatus($serviceStatus, $timeOut)
}

# check the audio service startup type
$audioEndpointServicestartupType = (Get-WmiObject -query "select * from win32_baseService where Name='AudioEndpointBuilder'").StartMode
$audioSrvstartupType = (Get-WmiObject -query "select * from win32_baseService where Name='Audiosrv'").StartMode

#resolver
if($audioEndpointServicestartupType -ne "auto")
{
    (Get-WmiObject -query "select * from win32_baseService where Name='AudioEndpointBuilder'").changeStartMode("automatic") > $null
}


if($audioSrvstartupType -ne "auto")
{
    (Get-WmiObject -query "select * from win32_baseService where Name='Audiosrv'").changeStartMode("automatic") > $null
}

Restart-Service AudioEndpointBuilder -Force
WaitFor-ServiceStatus "AudioEndpointBuilder" ([ServiceProcess.ServiceControllerStatus]::Running)

Restart-Service Audiosrv
WaitFor-ServiceStatus "Audiosrv" ([ServiceProcess.ServiceControllerStatus]::Running)