# Copyright © 2008, Microsoft Corporation. All rights reserved.

#
# Function to wait for expected service status
#
function WaitFor-ServiceStatus([string]$serviceName=$(throw "No service name is specified"), [ServiceProcess.ServiceControllerStatus]$serviceStatus=$(throw "No service status is specified"))
{
    [ServiceProcess.ServiceController]$sc = New-Object "ServiceProcess.ServiceController" $serviceName
    [TimeSpan]$timeOut = New-Object TimeSpan(0,0,0,5,0)
    $sc.WaitForStatus($serviceStatus, $timeOut)
}

function GetService($ServiceName)
{
	$Service = Get-Service -Name $ServiceName
	if( $Service -eq $null)
	{
		throw "Service not found, ServiceName='$ServiceName'"
	}

	return $Service
}

function ServiceRunning($ServiceName)
{
	$Service = GetService $ServiceName
	$StatusRunning = [System.ServiceProcess.ServiceControllerStatus]::Running

	return ($Service.Status -eq $StatusRunning)
}

function FixService($ServiceName)
{
	Set-Service -Name $ServiceName -StartupType Automatic
	Start-Service $ServiceName
	WaitFor-ServiceStatus $ServiceName ([ServiceProcess.ServiceControllerStatus]::Running)
}