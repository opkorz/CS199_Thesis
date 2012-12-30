# Copyright © 2008, Microsoft Corporation. All rights reserved.

#requires -version 2.0

$source = @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using NETWORKLIST;

namespace Microsoft.Windows.Diagnosis
{
    public sealed class NetListManager {
        private const string _networkLocationsRegPath = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\HomeGroup\\NetworkLocations";

        private NetListManager()
        {
        }

        public static bool ConnectedToAHomeNetwork()
        {
            bool isHome = false;

            try
            {
                NetworkListManager nlm = new NetworkListManager();
                IEnumNetworks connectedNetworks = nlm.GetNetworks(NLM_ENUM_NETWORK.NLM_ENUM_NETWORK_CONNECTED);

                foreach (INetwork network in connectedNetworks)
                {
                    try
                    {
                        if (network.GetCategory() == NLM_NETWORK_CATEGORY.NLM_NETWORK_CATEGORY_PRIVATE)
                        {
                            string networkID = "{" + network.GetNetworkId().ToString() + "}";
                            RegistryKey homeRegKey = Registry.LocalMachine.OpenSubKey(_networkLocationsRegPath + "\\Home");
                            if (homeRegKey != null)
                            {
                                if (homeRegKey.GetValue(networkID) != null)
                                {
                                    isHome = true;
                                    break;
                                }
                                homeRegKey.Close();
                            }
                        }
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine(e.ToString());
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }

            return isHome;
        }

        public static bool ConnectedToADomainNetwork()
        {
            bool isDomain = false;

            try
            {
                NetworkListManager nlm = new NetworkListManager();
                IEnumNetworks connectedNetworks = nlm.GetNetworks(NLM_ENUM_NETWORK.NLM_ENUM_NETWORK_CONNECTED);

                foreach (INetwork network in connectedNetworks)
                {
                    try
                    {
                        if (network.GetCategory() == NLM_NETWORK_CATEGORY.NLM_NETWORK_CATEGORY_DOMAIN_AUTHENTICATED)
                        {
                            isDomain = true;
                            break;
                        }
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine(e.ToString());
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }

            return isDomain;
        }

        public static bool SetAllConnectedNetworksHome()
        {
            bool success = true;
            try
            {
                NetworkListManager nlm = new NetworkListManager();
                IEnumNetworks connectedNetworks = nlm.GetNetworks(NLM_ENUM_NETWORK.NLM_ENUM_NETWORK_CONNECTED);

                foreach (INetwork network in connectedNetworks)
                {
                    try
                    {
                        String networkID = "{" + network.GetNetworkId().ToString() + "}";
                        String networkName = network.GetName();

                        RegistryKey workRegKey = Registry.LocalMachine.OpenSubKey(_networkLocationsRegPath + "\\Work", true);
                        if (workRegKey != null)
                        {
                            try
                            {
                                workRegKey.DeleteValue(networkID, false);

                                RegistryKey homeRegKey = Registry.LocalMachine.OpenSubKey(_networkLocationsRegPath + "\\Home", true);
                                if (homeRegKey != null)
                                {
                                    try
                                    {
                                        homeRegKey.DeleteValue(networkID, false);
                                        homeRegKey.SetValue(networkID.ToUpper(), networkName, RegistryValueKind.String);
                                    }
                                    catch (Exception e)
                                    {
                                        Console.WriteLine(e.ToString());
                                        success = false;
                                    }
                                    homeRegKey.Close();
                                }
                            }
                            catch (Exception e)
                            {
                                Console.WriteLine(e.ToString());
                                success = false;
                            }
                            workRegKey.Close();
                        }

                        if (network.GetCategory() != NLM_NETWORK_CATEGORY.NLM_NETWORK_CATEGORY_PRIVATE)
                        {
                            network.SetCategory(NLM_NETWORK_CATEGORY.NLM_NETWORK_CATEGORY_PRIVATE);
                        }
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine(e.ToString());
                        success = false;
                    }
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
                success = false;
            }
            return success;
        }

        public static int NumNetworksConnected()
        {
            int numNetworks = 0;

            try
            {
                NetworkListManager nlm = new NetworkListManager();
                IEnumNetworks connectedNetworks = nlm.GetNetworks(NLM_ENUM_NETWORK.NLM_ENUM_NETWORK_CONNECTED);

                foreach (INetwork network in connectedNetworks)
                {
                    numNetworks++;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }

            return numNetworks;
        }
    }
}
"@

$interopDllPath = "$ENV:SystemRoot\diagnostics\system\HomeGroup\Microsoft-Windows-HomeGroupDiagnostic.NetListMgr.Interop.dll"
Add-Type -ReferencedAssemblies $interopDllPath -TypeDefinition $source
[Reflection.Assembly]::LoadFile($interopDllPath);

function NumNetworks()
{
    return [Microsoft.Windows.Diagnosis.NetListManager]::NumNetworksConnected()
}

function CheckForHomeNetwork()
{
    return [Microsoft.Windows.Diagnosis.NetListManager]::ConnectedToAHomeNetwork()
}

function CheckForDomainNetwork()
{
    return [Microsoft.Windows.Diagnosis.NetListManager]::ConnectedToADomainNetwork()
}

function SetNetworkToHome()
{
    [Microsoft.Windows.Diagnosis.NetListManager]::SetAllConnectedNetworksHome()
}