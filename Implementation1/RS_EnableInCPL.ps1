# Copyright © 2008, Microsoft Corporation. All rights reserved.


PARAM($deviceID)
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

# Function to enable audio endpoint
function Enable-Endpoint([string]$id = $(throw "No ID is specified"))
{
    if([String]::IsNullOrEmpty($id))
    {
        throw "No id found"
    }

    (Get-IPolicyConfig)::SetEndpointVisibility($id, $true) > $null
}

Write-DiagProgress -activity $localizationString.enableEndpoint_progress

Enable-Endpoint $deviceID
