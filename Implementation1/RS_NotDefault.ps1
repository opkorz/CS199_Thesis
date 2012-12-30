# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceID)

. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

# Function to set an endpoint as default
function Set-DefaultEndpoint([string]$id = $(throw "No id is specified"))
{
    if([String]::IsNullOrEmpty($id))
    {
        throw "No id found"
    }

    (Get-IPolicyConfig)::SetDefaultEndpoint($id, (Get-ERole)::EConsole) > $null
    (Get-IPolicyConfig)::SetDefaultEndpoint($id, (Get-ERole)::EMultimedia) > $null
}

Write-DiagProgress -activity $localizationString.setAsDefault_progress

Set-DefaultEndpoint $deviceID
