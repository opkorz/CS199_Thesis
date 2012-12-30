# Copyright © 2008, Microsoft Corporation. All rights reserved.

trap { break }

# Load Common Library
. .\CL_Utility.ps1
. .\CL_RunDiagnosticScript.ps1

# function to check whether current package is running on remote session
function CheckRemoteSession {
    [string]$sourceCode = @"
using System;
using System.Runtime.InteropServices;

namespace Microsoft.Windows.Diagnosis {
    public static class RemoteManager {
        private const int SM_REMOTESESSION = 0x1000;

        [DllImport("User32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetSystemMetrics(int Index);

        public static bool Remote() {
            return (0 != GetSystemMetrics(SM_REMOTESESSION));
        }
    }
}
"@
    $type = Add-Type -TypeDefinition $sourceCode -PassThru

    return $type::Remote()
}

# Main diagnostic flow
if(CheckRemoteSession) {
    Get-DiagInput -ID "IT_RunOnRemoteSession"
    return
}

if((RunDiagnosticScript .\TS_SKU.ps1) -eq $false)
{
    return
}

if((RunDiagnosticScript .\TS_MirrorDriver.ps1) -eq $false) {
    return
}

if((RunDiagnosticScript .\TS_WinSat.ps1) -eq $false)
{
    return
}

if((RunDiagnosticScript .\TS_WDDMDriver.ps1) -eq $false)
{
    return
}

if((RunDiagnosticScript .\TS_HardwareSupport.ps1) -eq $false)
{
    return
}

RunDiagnosticScript .\TS_LowColorDepth.ps1

RunDiagnosticScript .\TS_UXSMS.ps1

if(RunDiagnosticScript .\TS_Themes.ps1) {
    RunDiagnosticScript .\TS_ColorTheme.ps1
}

if(RunDiagnosticScript .\TS_PowerPolicySetting.ps1) {
    RunDiagnosticScript .\TS_Transparency.ps1
}

RunDiagnosticScript .\TS_DWMEnable.ps1