# Copyright © 2008, Microsoft Corporation. All rights reserved.


Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.uxsms_progress

# check Whether the service of UxSms is existent

[bool]$uxsmsState = $false

$wmiService = (Get-WmiObject -query "select * from win32_baseService where Name='Uxsms'")

if($wmiService -eq $null)
{
    $uxsmsState = $false
}
else
{
    $uxsmsState = $wmiService.state -eq "Running"
}

if(-not($uxsmsState))
{
    Update-DiagRootCause -id "RC_UXSMS" -Detected $true
} else {
    Update-DiagRootCause -id "RC_UXSMS" -Detected $false
}

return $uxsmsState
