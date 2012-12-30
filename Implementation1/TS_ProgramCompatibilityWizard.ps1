# Copyright © 2008, Microsoft Corporation. All rights reserved.


#TS_ProgramCompatibilityWizard
#rparsons - 05 May 2008

$ShortcutListing = New-Object System.Collections.Hashtable
$ExeListing = New-Object System.Collections.ArrayList
$CombinedListing = New-Object System.Collections.ArrayList

Import-LocalizedData -BindingVariable CompatibilityStrings -FileName CL_LocalizationData

$typeDefinition = @"

using System;
using System.IO;
using System.Runtime.InteropServices;

public class Utility
{
    public static string GetStartMenuPath()
    {
        return Environment.GetFolderPath(Environment.SpecialFolder.StartMenu);
    }

    public static string GetAllUsersStartMenuPath()
    {
        return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "Microsoft\\Windows\\Start Menu");
    }

    public static string GetDesktopPath()
    {
        return Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
    }

    [DllImport("sfc.dll", SetLastError=true, EntryPoint="SfcIsFileProtected", CharSet=CharSet.Unicode)]
    [return : MarshalAs(UnmanagedType.Bool)]
    public static extern bool SfcIsFileProtected(IntPtr RpcHandle, String ProtFileName);

    public static bool IsFileProtected(String FileName)
    {
        return SfcIsFileProtected(IntPtr.Zero, FileName);
    }
}
"@

$typeDefinition2 = @"

using System;
using System.Collections;
using System.Diagnostics;
using System.IO;

public class ProgramSorter : IComparer
{
    int IComparer.Compare(Object x, Object y)
    {
        string friendlyNameX = GetFriendlyName(x.ToString());
        string friendlyNameY = GetFriendlyName(y.ToString());

        return friendlyNameX.CompareTo(friendlyNameY);
    }

    public string GetFriendlyName(string path)
    {
        if (path.EndsWith(".lnk"))
        {
            return Path.GetFileNameWithoutExtension(path);
        }

        FileVersionInfo versionInfo = FileVersionInfo.GetVersionInfo(path);
        string friendlyName = null;

        if(versionInfo != null)
        {
            if(versionInfo.FileDescription != null)
            {
                friendlyName = versionInfo.FileDescription.Trim();
            }
        }

        if((friendlyName == null) || (friendlyName == String.Empty))
        {
            friendlyName = Path.GetFileNameWithoutExtension(path);
        }

        return friendlyName;
    }
}
"@


$typeDefinition3 = @"

using System;
using System.Runtime.InteropServices;
using System.Text;

public class ExeFromLnk
{
    const int MAX_PATH = 260;

    [DllImport("acppage.dll", EntryPoint="GetExeFromLnk", CharSet=CharSet.Unicode)]
    [return : MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetExeFromLnk(String pszLnk, StringBuilder pszExe, int cchSize);

    public static String GetTargetExePath(String LinkPath)
    {
        StringBuilder exePath = new StringBuilder(MAX_PATH);
        if (GetExeFromLnk(LinkPath, exePath, exePath.Capacity))
        {
            return exePath.ToString().Replace("$", "`$");
        }

        return String.Empty;
    }

    public static String EscapePath(String Path)
    {
        return Path.Replace("$", "`$");
    }
}
"@

$type = Add-Type -TypeDefinition $typeDefinition -PassThru
$type3 = Add-Type -TypeDefinition $typeDefinition3 -PassThru

# Function to convert to WQL path
function ConvertTo-WQLPath([string]$wqlPath = $(throw "No path is specified"))
{
    if($wqlPath -eq $null)
    {
        return $false
    }

    return $wqlPath.Replace("\", "\\")
}

# Function to retrieve all of the shortcuts from the provided directory
function Get-ShortcutList([string]$path = $(throw $CompatibilityStrings.Throw_NO_PATH))
{
    Get-ChildItem -Path $path -recurse -filter *.lnk | Foreach-Object {
        $fullPath = ConvertTo-WQLPath($_.FullName)

        $exePath = $type3::GetTargetExePath($fullPath)

        if(($exePath -ne $null) -and -not([String]::IsNullOrEmpty($exePath)) -and ([System.IO.Path]::GetExtension($exePath) -eq ".exe"))
        {
            if(Test-Path $exePath)
            {
                if(-not($type::IsFileProtected($exePath)))
                {
                    if(-not($ShortcutListing.ContainsKey($fullPath)) -and -not($ShortcutListing.ContainsValue($exePath)))
                    {
                        [System.Collections.Hashtable]$ShortcutListing.Add($fullPath, $exePath)
                    }
                }
            }
        }
    }
}

# Function to retrieve all the executables from the provided directory
function Get-ExeList([string]$path = $(throw $CompatibilityStrings.Throw_NO_PATH))
{
    Get-ChildItem -Path $path -recurse -filter *.exe | Foreach-Object {
        $exePath = $_.FullName.Replace("$", "`$")

        if(Test-Path $exePath)
        {
            if(-not($type::IsFileProtected($exePath)))
            {
                if(-not($ExeListing.Contains($exePath)) -and -not($ShortcutListing.ContainsValue($exePath)))
                {
                    $ExeListing.Add($exePath)
                }
            }
        }
    }
}

# Function to determine whether the selected program is valid
function Test-Selection([string]$appPath)
{
    $testresult = $false

    if(($appPath -ne $null) -and -not([String]::IsNullOrEmpty($appPath)))
    {
        $testresult = test-path $appPath

        if($testresult)
        {
            if(-not($type::IsFileProtected($appPath)))
            {
                $extension = [System.IO.Path]::GetExtension($appPath)
                $testresult = ($extension -eq ".exe") -or ($extension -eq ".msi")
            }
            else
            {
                $testresult = $false
                Set-Variable -name rebrowseText -value $CompatibilityStrings.Text_FILE_PROTECTED -scope global
            }
        }
    }

    Set-Variable -name appValid -value $testResult -scope global
}

$LaunchMethod = "ControlPanel"

try {
    $LaunchMethod = Get-DiagInput -id IT_LaunchMethod -errorAction silentlyContinue
}
# MSDT_E_NO_ANSWER_NOUI
catch {
    $LaunchMethod = "ControlPanel"
}

[string]$startMenuPath = $type::GetStartMenuPath()
[string]$allUsersStartMenuPath = $type::GetAllUsersStartMenuPath()
[string]$desktopPath = $type::GetDesktopPath()

$choices = New-Object System.Collections.ArrayList
set-variable ChoicesAvailable $false -scope global

#Add a 'Not Listed' entry
$notListedChoice = @{}
$notListedChoice.Add("Name", $CompatibilityStrings.Program_Choice_NOTLISTED)
$notListedChoice.Add("Description", $CompatibilityStrings.Program_Choice_NOTLISTED)
$notListedChoice.Add("Value", "NotListed")

$choices += $notListedChoice

if($LaunchMethod -ne "ContextMenu")
{
    Write-DiagProgress -activity $CompatibilityStrings.Text_Activity_TROUBLESHOOTING -status $CompatibilityStrings.Text_Status_SEARCHING

    Get-ShortcutList($startMenuPath)
    Get-ShortcutList($allUsersStartMenuPath)
    Get-ShortcutList($desktopPath)
    Get-ExeList($desktopPath)

    #Combine the entries into one list for sorting
    foreach($pathKey in $ShortcutListing.keys)
    {
        $CombinedListing.Add($pathKey)
    }

    foreach($exePath in $ExeListing)
    {
        $CombinedListing.Add($exePath)
    }

    #Sort the combined list
    Add-Type -TypeDefinition $typeDefinition2
    $programSorter = New-Object ProgramSorter
    $CombinedListing.Sort($programSorter)

    #Add choices for each entry in the combined list
    foreach($path in $CombinedListing)
    {
        Set-Variable -name ChoicesAvailable -value $true -scope global
        $friendlyName = $programSorter.GetFriendlyName($path)
        $fullPathToTarget = $path

        if ($path.EndsWith(".lnk"))
        {
            $fullPathToTarget = $ShortcutListing[$path]
        }

        $choice = @{}
        $choice.Add("Name", $friendlyName)
        $choice.Add("Description", $fullPathToTarget)
        $choice.Add("Value", $fullPathToTarget)

        $choices += $choice
    }
}

if(-not($ChoicesAvailable))
{
    $selectedProgram = Get-DiagInput -id IT_BrowseForFile
}
else
{
    $selectedProgram = Get-DiagInput -id IT_SelectProgram -choice $choices

    if($selectedProgram -eq "NotListed")
    {
        $selectedProgram = Get-DiagInput -id IT_BrowseForFile
    }

}

Set-Variable -name rebrowseText -value $CompatibilityStrings.Text_FILE_INVALID -scope global
Set-Variable -name appValid -value $false -scope global
Test-Selection($selectedProgram)

$InstanceId = 0

while(-not($appValid))
{
    $InstanceId++
    $selection = $selectedProgram
    $selectedProgram = Get-DiagInput -id IT_RebrowseForFile -parameter @{ "SelectedProgram" = $selection; "RebrowseText" = $rebrowseText; "Instance" = $InstanceId }
    Set-Variable -name rebrowseText -value $CompatibilityStrings.Text_FILE_INVALID -scope global
    Test-Selection($selectedProgram)
}

$appName = [System.IO.Path]::GetFileNameWithoutExtension($selectedProgram).Replace("$", "`$")

#Go back through the choices to find the display name for the selected application.
foreach ($choice in $choices)
{
    if($choice["Value"] -eq $selectedProgram)
    {
        $appName = $choice["Name"].Replace("$", "`$")
        break
    }
}

#TODO: Shortcut icon index not working properly?
Update-DiagRootCause -id "RC_IncompatibleApplication" -Detected $true -parameter @{ "TARGETPATH" = $selectedProgram; "APPNAME" = $appName}

