# Copyright � 2008, Microsoft Corporation. All rights reserved.

# Restore correct permissions on the indexer data directories.
#
# Correct permissions on the parent of the data directory look like this:
#
# FileSystemRights  : FullControl
# AccessControlType : Allow
# IdentityReference : NT AUTHORITY\SYSTEM
# IsInherited       : True
# InheritanceFlags  : ContainerInherit, ObjectInherit
# PropagationFlags  : None
#
# FileSystemRights  : FullControl
# AccessControlType : Allow
# IdentityReference : BUILTIN\Administrators
# IsInherited       : True
# InheritanceFlags  : ContainerInherit, ObjectInherit
# PropagationFlags  : None
#
# FileSystemRights  : ReadAndExecute, Synchronize
# AccessControlType : Allow
# IdentityReference : BUILTIN\Users
# IsInherited       : True
# InheritanceFlags  : ContainerInherit, ObjectInherit
# PropagationFlags  : None
#
# FileSystemRights  : ReadAndExecute, Synchronize
# AccessControlType : Allow
# IdentityReference : Everyone
# IsInherited       : True
# InheritanceFlags  : ContainerInherit, ObjectInherit
# PropagationFlags  : None

# Load utility library
. .\CL_Utility.ps1

# To change ACEs, SDDL must have BUILTIN\Administrators as owner instead of SYSTEM.
# Otherwise, we get an error because Set-Acl tries to change the owner before the ACEs, and we are not SYSTEM.
$sddl = "O:BAG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)"

Write-DiagProgress -activity $localizationString.progress_rs_restorePermissions

$dataDirectory = (Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows Search").DataDirectory

# First change the ACEs with BUILTIN\Administrators as owner
$acl = get-acl $dataDirectory
$acl.SetSecurityDescriptorSddlForm($sddl)
set-acl -path $dataDirectory -aclObject $acl
# Now change the owner to SYSTEM ("S-1-5-18") (This requires asserting SeRestorePrivilege.)
Set-RestorePrivilege
$acl = get-acl $dataDirectory
$account = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
$acl.SetOwner($account)
set-acl -path $dataDirectory -aclObject $acl
