# Copyright © 2008, Microsoft Corporation. All rights reserved.


#
# Check the status of the spooler service. If the service is not running, add the root cause.
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.progress_ts_SpoolerService

if((get-service spooler).status -ne "Running")
{
    Update-DiagRootCause -id "RC_SpoolerService" -Detected $true
    return $false
}
else
{
    Update-DiagRootCause -id "RC_SpoolerService" -Detected $false
    return $true
}
