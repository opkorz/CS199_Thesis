# Copyright © 2008, Microsoft Corporation. All rights reserved.

#
# Terminate the script on any uncaught exception
#
trap { break }


#
# Check windows update connectivity issue
#
Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

Write-DiagProgress -activity $localizationString.progress_ts_connectivity

#
# Convert string to the PSObject and set the string as property value to specified property name
#
function ConvertStringToPSObject([string]$propertyName, [string]$propertyValue)
{
    $obj = New-Object -TypeName System.Management.Automation.PSObject
    Add-Member -InputObject $obj -MemberType NoteProperty -Name $propertyName -Value $propertyValue
    return $obj
}
#
# Write API exception in file to debug report
#
function WriteFileAPIExceptionReport([string]$fileName, [string]$info)
{
    [string]$exceptionInfo = [System.String]::Format([System.Globalization.CultureInfo]::InvariantCulture, $localizationString.errorInfo_content, $fileName, $info)
    $obj = ConvertStringToPSObject "exceptionInformation" $exceptionInfo
    $obj | select-object -Property @{ Name=$exceptionInfo; Expression={$_.exceptionInformation}} | convertto-xml | Update-DiagReport -ID "ErrorInfo" -name $localizationString.errorInfo_name -verbosity Debug
}

#
# Trouble shooter issues
#
[string]$fileName = "TS_Connectivity.ps1"

$updateSession = New-Object -ComObject Microsoft.Update.Session
if($updateSession -eq $null)
{
    WriteFileAPIExceptionReport $fileName "Microsoft.Update.Session"
    return
}
$updateSearch = $updateSession.CreateUpdateSearcher()
if($updateSearch -eq $null)
{
    WriteFileAPIExceptionReport $fileName "CreateUpdateSearcher"
    return
}

[bool]$addRootCause = $false
$errorAction = $local:ErrorActionPreference
$local:ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
try
{
    $updateSearch.Search("IsInstalled=0 and Type='Software'")

}
catch
{
    $err = $error[0]
    $hresult =  $error[0].exception.innerexception.innerexception.errorcode
    if ($hresult -eq $null)
    {
       throw $_
    }
    $addRootCause = $true
}
finally
{
    $local:ErrorActionPreference = $errorAction
}

if($addRootCause)
{
    if ($hresult)
    {
        $customCode = 'WindowsUpdate_dt000+WindowsUpdate_' + $hresult.ToString("X")
        Update-DiagRootcause -Id "RC_Connectivity" -Detected $true -p @{'ScanFailure'='true';'Keywords'=$customCode}

        $hresult | select-object -Property @{Name=$localizationString.scanInfo_error; Expression={$_}} |convertto-xml | Update-DiagReport -id "ScanErrorInfo" -name $localizationString.scanInfo_name -description $localizationString.scanInfo_description -verbosity Informational -rid "RC_Connectivity"
    }

    $event = get-winevent -FilterHashTable @{ LogName = "Microsoft-Windows-WindowsUpdateClient/Operational"; ID=29 } -MaxEvents 1
    if($event -ne $null)
    {
        $event | convertto-xml | Update-DiagReport -id LostConnectivity -name $localizationString.lostConnectivity_name -description $localizationString.lostConnectivity_description -verbosity Informational -rid "RC_Connectivity"

    }
}
else
{
    Get-DiagInput -ID "IT_LaunchWU"
    Update-DiagRootcause -Id "RC_Connectivity" -Detected $false
}
