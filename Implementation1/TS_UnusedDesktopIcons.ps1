# Copyright © 2008, Microsoft Corporation. All rights reserved.

# Check Unused desktop icons
. .\CL_Utility.ps1

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

# Function to check whether the icon is unused (and ignore nerver used icons)
function Test-Unused([DateTime]$lastAccessTime = $(throw "No last access time is specified"), [int]$threshold = $(3))
{
    [bool]$result = $false

    if($lastAccessTime -eq $null)
    {
        return $result
    }

    return ([DateTime]::Compare([DateTime]::Now, $lastAccessTime.AddMonths($threshold)) -gt 0) -and ($lastAccessTime.Year -gt 1601)
}

# Function to get a list of unused links
function Get-UnusedShortcutList([string]$path = $(throw "No path is specified"), [int]$threshold = $(throw "No threshold is specified"))
{
    [string]$list = ""
    Get-ChildItem -Path $path -filter *.lnk | Foreach-Object {
        $fullPath = ConvertTo-WQLPath $_.FullName
        $wmiLinkFile = Get-WmiObject -query "SELECT Name,Target,AccessMask FROM Win32_ShortcutFile WHERE Name = '$fullPath'"
        $lastAccessTime = Get-LastAccessTime $_.FullName

        if((Test-ValidLink $wmiLinkFile) -and (Test-Delete $wmiLinkFile) -and (Test-FileShortcut $wmiLinkFile) -and (Test-Unused $lastAccessTime $threshold))
        {
            $list = AttachTo-List $list $wmiLinkFile.Name
        }
    }

    return $list
}

[string]$desktopPath = Get-DesktopPath
[string]$unusedDesktopIcons = ""
[int]$threshold = 3

Write-DiagProgress -activity $localizationString.checkUnusedDesktopIcons_Progress
$unusedDesktopIcons = (Get-UnusedShortcutList $desktopPath $threshold)

if(-not([String]::IsNullOrEmpty($unusedDesktopIcons)))
{
    Parse-List $unusedDesktopIcons | Select-Object -Property @{Name=$localizationString.shortcutName;Expression={$_}} | ConvertTo-Xml | Update-DiagReport -id UnusedDesktopShortcutsList -Name $localizationString.unusedDesktopShortcuts_name -Description ($localizationString.unusedDesktopShortcuts_description + " " + $threshold + " " + $localizationString.unusedTimeUnit) -Verbosity Informational -rid "RC_UnusedDesktopIcons"

    if((Get-ListLength $unusedDesktopIcons) -gt 10)
    {
        Update-DiagRootCause -id "RC_UnusedDesktopIcons" -Detected $true -parameter @{'UnusedDesktopShortcuts'=$unusedDesktopIcons; 'Threshold'=$threshold}
        return
    }
}

Update-DiagRootCause -id "RC_UnusedDesktopIcons" -Detected $false -parameter @{'UnusedDesktopShortcuts'=$unusedDesktopIcons; 'Threshold'=$threshold}