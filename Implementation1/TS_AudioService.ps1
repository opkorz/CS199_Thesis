# Copyright © 2008, Microsoft Corporation. All rights reserved.


Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.audioService_progress

# check Whether the service of audio service is existent
$audioService = (Get-WmiObject -query "select * from win32_baseService where Name='Audiosrv'")
$audioEndpointBuilderService = (Get-WmiObject -query "select * from win32_baseService where Name='AudioEndpointBuilder'")

if(($audioService -eq $NULL) -or ($audioEndpointBuilderService -eq $null))
{
    return $false
}

# check the audio service status
[bool]$result = ($audioService.State -eq "Running") -and ($audioEndpointBuilderService.State -eq "Running")

if(-not($result))
{
    Update-DiagRootCause -id "RC_AudioService" -Detected $true
} else {
    Update-DiagRootCause -id "RC_AudioService" -Detected $false
}

return $result
