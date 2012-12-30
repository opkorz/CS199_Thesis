# Copyright © 2008, Microsoft Corporation. All rights reserved.

Import-LocalizedData -BindingVariable localizationString -FileName CL_LocalizationData

[string]$featureFileName = "features.xml"

function GetAbsolutionPath([string]$fileName = $(throw "No file name is specified"))
{
    if([string]::IsNullorEmpty($fileName))
    {
        throw "Invalid file name"
    }

    return Join-Path (Get-Location).Path $fileName
}

function GetSystemPath([string]$fileName = $(throw "No file name is specified"))
{
    if([string]::IsNullorEmpty($fileName))
    {
        throw "Invalid file name"
    }

    [string]$systemPath = [System.Environment]::SystemDirectory
    return Join-Path $systemPath $fileName
}

function GetRuntimePath([string]$fileName = $(throw "No file name is specified"))
{
    if([string]::IsNullorEmpty($fileName))
    {
        throw "Invalid file name"
    }

    [string]$runtimePath =  [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
    return Join-Path $runtimePath $fileName
}

function UpdateFeatureAssessment()
{
    [string]$winSatCmd = GetSystemPath "WinSat.exe"
    & $winSatCmd features -xml $featureFileName
}

function GetLatestAssessmentFile()
{
    UpdateFeatureAssessment | Out-Null

    return (Resolve-Path ".\$featureFileName").Path
}

function Check-Transparency()
{
[string]$typeDefination = @"

using System;
using System.Runtime.InteropServices;

public sealed class DWMHelper
{
    private DWMHelper()
    {
    }

  [DllImport("dwmapi.dll", PreserveSig=false)]
  private static extern int DwmGetColorizationColor(ref int color, [MarshalAs(UnmanagedType.Bool)] ref bool opaque);

  public static bool IsTransparency()
  {
    int color = 0;
    bool opaque = true;

    DwmGetColorizationColor(ref color, ref opaque);

    return !opaque;
  }
}

"@
    return (Add-Type -TypeDefinition $typeDefination -PassThru)::IsTransparency()
}

# Function to get power policy info
function Get-PowerPolicyInfo([string]$cmdOutput = $(throw "No cmd output is specified"))
{
    if([String]::IsNullOrEmpty($cmdOutput))
    {
         return ""
    }

    [string]$powerPolicyinfo = ""
    if($cmdOutput -match "[\w\W]+: ([\w\W]+)")
    {
        $powerPolicyinfo = $matches[1]
    }

    return $powerPolicyinfo
}

# ThemeManagement Source code
function Get-ThemeManagementSourceCode()
{
    return @"
using System;
using System.IO;
using System.CodeDom.Compiler;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Security.Permissions;
using System.Globalization;

[assembly: CLSCompliant(true)]
[assembly: SecurityPermission(SecurityAction.RequestMinimum, Execution = true)]
namespace ThemeManagement
{
    public static class ThemeManagerCaller
    {
        [PermissionSet(SecurityAction.LinkDemand)]
        public static bool CompileCSCode(string source, string path)
        {
            if (String.IsNullOrEmpty(source) || String.IsNullOrEmpty(path))
            {
                throw new ArgumentException(String.Format(CultureInfo.InvariantCulture, "Invalid source or path"));
            }

            CodeDomProvider compiler = new Microsoft.CSharp.CSharpCodeProvider();

            CompilerParameters compileParms = new CompilerParameters();
            compileParms.GenerateExecutable = true;
            compileParms.GenerateInMemory = false;
            compileParms.IncludeDebugInformation = false;
            compileParms.OutputAssembly = path;
            compileParms.ReferencedAssemblies.Add("System.dll");

            CompilerResults compilerResult = compiler.CompileAssemblyFromSource(compileParms, source);
            return compilerResult.Errors.Count == 0;
        }
    }
}
"@
}

# Function to get theme API source code
Function Get-ThemeSourceCode()
{
    return @"
namespace ThemeApi
{
    using System;
    using System.IO;
    using System.Globalization;
    using System.Security;
    using System.Security.Permissions;
    using System.Runtime.InteropServices;
    using System.Runtime.CompilerServices;

    public static class ThemeManagerHelpClass
    {
        [ComImport, Guid("D23CC733-5522-406D-8DFB-B3CF5EF52A71"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface ITheme
        {
            [DispId(0x60010000)]
            string DisplayName
            {
                [return: MarshalAs(UnmanagedType.BStr)]
                [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
                get;
            }

            [DispId(0x60010001)]
            string VisualStyle
            {
                [return: MarshalAs(UnmanagedType.BStr)]
                [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
                get;
            }
        }

        [ComImport, Guid("0646EBBE-C1B7-4045-8FD0-FFD65D3FC792"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface IThemeManager
        {
            [DispId(0x60010000)]
            ITheme CurrentTheme
            {
                [return: MarshalAs(UnmanagedType.Interface)]
                [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
                get;
            }

            [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
            void ApplyTheme([In, MarshalAs(UnmanagedType.BStr)] string bstrThemePath);
        }

        [ComImport, Guid("A2C56C2A-E63A-433E-9953-92E94F0122EA"), CoClass(typeof(ThemeManagerClass))]
        public interface ThemeManager : IThemeManager { }

        [ComImport, Guid("C04B329E-5823-4415-9C93-BA44688947B0"), ClassInterface(ClassInterfaceType.None), TypeLibType(TypeLibTypeFlags.FCanCreate)]
        public class ThemeManagerClass : IThemeManager, ThemeManager
        {
            [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
            public virtual extern void ApplyTheme([In, MarshalAs(UnmanagedType.BStr)] string bstrThemePath);

            [DispId(0x60010000)]
            public virtual extern ITheme CurrentTheme
            {
                [return: MarshalAs(UnmanagedType.Interface)]
                [MethodImpl(MethodImplOptions.InternalCall, MethodCodeType = MethodCodeType.Runtime)]
                get;
            }
        }

        private static class NativeMethods
        {
            [DllImport("UxTheme.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool IsThemeActive();
        }

        private static IThemeManager themeManager = new ThemeManagerClass();

        [PermissionSet(SecurityAction.LinkDemand)]
        public static string GetCurrentThemeName()
        {
            return themeManager.CurrentTheme.DisplayName;
        }

        [PermissionSet(SecurityAction.LinkDemand)]
        public static void ChangeTheme(string themeFilePath)
        {
            themeManager.ApplyTheme(themeFilePath);
        }

        [PermissionSet(SecurityAction.LinkDemand)]
        public static string GetCurrentVisualStyleName()
        {
            return Path.GetFileName(themeManager.CurrentTheme.VisualStyle);
        }

        public static string GetThemeStatus()
        {
            return NativeMethods.IsThemeActive() ? "running" : "stopped";
        }

        [STAThread(), PermissionSet(SecurityAction.LinkDemand)]
        public static void Main(string[] args)
        {
            if (args.Length < 1)
            {
                return;
            }

            string result = "";
            string methodName = args[0].ToLower(CultureInfo.InvariantCulture);

            try
            {
                if (String.Compare(methodName, "getcurrentthemename") == 0)
                {
                    result = GetCurrentThemeName();
                }
                else if (String.Compare(methodName, "changetheme") == 0)
                {
                    if (args.Length < 2)
                    {
                        return;
                    }

                    ChangeTheme(args[1]);
                }
                else if (String.Compare(methodName, "getcurrentvisualstylename") == 0)
                {
                    result = GetCurrentVisualStyleName();
                }
                else if (String.Compare(methodName, "getthemestatus") == 0)
                {
                    result = GetThemeStatus();
                }
                else
                {
                    return;
                }
            }
            catch
            {
                result = "";
            }

            Console.WriteLine(String.Format(CultureInfo.InvariantCulture, result));
        }
    }
}
"@
}

# Function to wrap theme API caller
function Compile-CSCode([string]$source = $(throw "No source is specified"), [string]$path = $(throw "No path is specified"))
{
    if([String]::IsNullOrEmpty($source))
    {
        throw "No source found"
    }

    if([String]::IsNullOrEmpty($path))
    {
        throw "No path found"
    }

    [bool]$result = $true
    if(Test-Path $path)
    {
        return $true
    }

    try
    {
        [string]$ThemeManagementSource = Get-ThemeManagementSourceCode
        $type = Add-Type -TypeDefinition $ThemeManagementSource -PassThru
        $result = $type::CompileCSCode($source, $path)
    }
    catch
    {
        $result = $false
    }

    return $result
}

# Function to call theme API
function Invoke-Method([string]$source = $(throw "No source is specified"), [string]$themeToolName = $(throw "No theme tool name is specified"), [string]$methodName = $(throw "No method name is specified"))
{
    if([String]::IsNullOrEmpty($source))
    {
        throw "No source found"
    }

    if([String]::IsNullOrEmpty($themeToolName))
    {
        throw "No theme tool name found"
    }

    if([String]::IsNullOrEmpty($methodName))
    {
        throw "No method name found"
    }

    [string]$result = ""

    if(-not(Compile-CSCode $source $themeToolName))
    {
        return ""
    }

    return (Invoke-Expression ".\$themeToolName $methodName").Trim()
}

# Function to convert power source name
function ConvertTo-PowerSourceName($powerSource=$(throw "No power source is specified")) {
    [string]$powerSourceName = ""
    if(([Windows.Forms.PowerLineStatus]::Online) -eq $lineOn) {
        $powerSourceName = ($localizationString.onlinePowerSource)
    } elseif (([Windows.Forms.PowerLineStatus]::Offline) -eq $lineOn) {
        $powerSourceName = ($localizationString.offlinePowerSource)
    } else {
        $powerSourceName = ($localizationString.unknownPowerSource)
    }

    return $powerSourceName
}

# Function to wait for expected service status
function WaitFor-ServiceStatus([string]$serviceName=$(throw "No service name is specified"), [ServiceProcess.ServiceControllerStatus]$serviceStatus=$(throw "No service status is specified")) {
    [ServiceProcess.ServiceController]$sc = New-Object "ServiceProcess.ServiceController" $serviceName
    [TimeSpan]$timeOut = New-Object TimeSpan(0,0,0,5,0)
    $sc.WaitForStatus($serviceStatus, $timeOut)
}