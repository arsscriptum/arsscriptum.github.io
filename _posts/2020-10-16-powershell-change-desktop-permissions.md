---
layout: post
title:  "Restricting Desktop folder Permissions"
summary: "Restricting Desktop folder Permissions with PowerShell"
author: guillaume
date: '2020-10-16'
category: ['powershell','scripts', 'useless']
tags: powershell, scripts, useless
thumbnail: /assets/img/posts/powershell-restrict-desktop-permissions.png
keywords: progress, powershell
usemathjax: false
permalink: /blog/powershell-restrict-desktop-permissions/

---

### Changing a user's Desktop folder Permissions with PowerShell Script  </h3>


-------------------


This PowerShell scripts helps in quickly setting the users desktop permissions so that it's only modifiable by an admin. I did this today because of
a [Reddit user](https://www.reddit.com/user/mudderfudden/) was asking [how to set the Desktop folder](https://www.reddit.com/r/PowerShell/comments/y56wqr/is_it_possible_to_set_the_desktop_folder_such/) such that only an Administrator can edit it's content, Still users have to be able to browse and use their shortcuts.

### Set-RestrictedDesktopAccess </h3>

This script is used to change the access control on a user's desktop folder so that only the administrator can modify it. The user can still open/execute shortcuts but not change the
content of the desktop folder.

#### Details 

The file receive the name of a local user as an argument. There is autocompletion to avoid bad entries. **The execution needs to be done as admin**
Then the function resolve the user desktop folder, will get the list of files and sub folders and change the ACLs, and remove the inheritance.

### Reset-AccessRights 

This function will revert the changes done by ```Set-RestrictedDesktopAccess``` by re-enabling inheritance and purging the added acls.


#### How To Use 

to *test* before **-WhatIF**

```
    # This is for a TEST (will not change anything) -- RECOMMENDED BEFORE DOING SOMETHING MORE  
    $Changed = .\Set-RestrictedDesktopAccess.ps1 -UserName JohnDoe -WhatIf -Verbose
    # List the changes
    $Changed
```


```
    # as administrator
    $Changed = .\Set-RestrictedDesktopAccess.ps1 -UserName JohnDoe
```


-------------------

#### Quick Demo 


<img class="card-img-top-restricted-60"
     src="/assets/img/posts/restrict-desktop-permissions-demo.gif"
     alt="Demo" />



-------------------


```powershell
    
    function Set-RestrictedAccessRights{
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [Parameter(Mandatory=$true,Position=0)]
            [Alias('p', 'f','File')]
            [string[]]$Paths,
            [Parameter(Mandatory=$true,Position=1)]
            [Alias('u')]
            [ValidateScript({
                if ([string]::IsNullOrEmpty($_)) {
                    throw "Invalid username specified `"$1`""
                }
                else {
                    $Owner = $_
                    $UsrOrNull = (Get-LocalUser -ErrorAction Ignore).Name  | Where-Object { $_ -match "$Owner"}
                    if ([string]::IsNullOrEmpty($UsrOrNull)) {
                        throw "Invalid username specified `"$Owner`""
                    }
                }
                return $true 
            })]
            [string]$Owner
        )
        Begin{
            $is_admin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) 
            if($False -eq $is_admin)   { throw "Administrator privileges required" } 
            $object_count = $Paths.Count
            $username = (Get-LocalUser).Name -replace '(.*\s.*)',"'`$1'" | Where-Object { $_ -match "$Owner"}
            Write-Verbose "Set-RestrictedAccessRights for owner $Owner. Num $object_count paths"

            $admin_account_name = Get-AdminAccountName
            Write-Verbose "Get-AdminAccountName => $admin_account_name"

        }
        Process{
          try{

            $usr_allow  = "$ENV:USERDOMAIN\$username"           , 'ReadAndExecute,Synchronize'  , 'none, none'  , 'None', 'Allow'
            $adm_allow  = "$ENV:USERDOMAIN\$admin_account_name"   , 'FullControl'                 , 'none, none'  , 'None', 'Allow'

            $secobj_admin_allow = New-Object System.Security.AccessControl.FileSystemAccessRule $adm_allow 
            $secobj_user_allow  = New-Object System.Security.AccessControl.FileSystemAccessRule $usr_allow 
            if($Null -eq $secobj_admin_allow)   { throw "Error on FileSystemAccessRule creation $adm_allow" }
            if($Null -eq $secobj_user_allow)    { throw "Error on FileSystemAccessRule creation $usr_allow" }
            [system.collections.arraylist]$results = [system.collections.arraylist]::new()
            ForEach($obj in $Paths){
                $userobject = New-Object System.Security.Principal.NTAccount("$ENV:USERDOMAIN", "$username")
                $acl = Get-Acl -Path $obj
                $acl.SetAccessRuleProtection($true, $false)
                $acl.SetAccessRule($secobj_user_allow)
                $acl.AddAccessRule($secobj_admin_allow)
                $acl.SetOwner($userobject)
                Write-Verbose "Save the access rules for `"$obj`""
                # Save the access rules to disk:
                try{
                    $acl | Set-Acl $obj -ErrorAction Stop
                    #Write-Host "Set-RestrictedAccessRights `"$obj`""
                    [void]$results.Add($obj)
                }catch{
                    Write-Host "Set-Acl ERROR `"$obj`" $_" -f Red
                }
            }
            Write-Verbose "$($results.Count) paths modified"
            $results
          }catch{
            Write-Error $_
          }
        }
    }


```

---------------------------------------------------------------------------------------------------------

#### Reset-AccessRights 

This is how we change the folders ACLS. Resetting the owner at the same time:




```powershell

    function Reset-AccessRights{
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [Parameter(Mandatory=$true,Position=0)]
            [Alias('p', 'f','File')]
            [string[]]$Paths,
            [Parameter(Mandatory=$true,Position=1)]
            [Alias('u')]
            [ValidateScript({
                if ([string]::IsNullOrEmpty($_)) {
                    throw "Invalid username specified `"$1`""
                }
                else {
                    $Owner = $_
                    $UsrOrNull = (Get-LocalUser -ErrorAction Ignore).Name  | Where-Object { $_ -match "$Owner"}
                    if ([string]::IsNullOrEmpty($UsrOrNull)) {
                        throw "Invalid username specified `"$Owner`""
                    }
                }
                return $true 
            })]
            [string]$Owner
        )
        Begin{
            $is_admin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) 
            if($False -eq $is_admin)   { throw "Administrator privileges required" } 
            $object_count = $Paths.Count
            $username = (Get-LocalUser).Name -replace '(.*\s.*)',"'`$1'" | Where-Object { $_ -match "$Owner"}
            Write-Verbose "Reset-AccessRights for owner $Owner. Num $object_count paths"

            $admin_account_name = Get-AdminAccountName
            Write-Verbose "Get-AdminAccountName => $admin_account_name"

        }
        Process{
          try{

            $usr_allow  = "$ENV:USERDOMAIN\$username"               , 'FullControl'  , "none, none","none","Allow"
            $secobj_user_allow  = New-Object System.Security.AccessControl.FileSystemAccessRule $usr_allow 
            $i = 0
            Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete 0
            if($Null -eq $secobj_user_allow)    { throw "Error on FileSystemAccessRule creation $usr_allow" }
            [system.collections.arraylist]$results = [system.collections.arraylist]::new()
            ForEach($obj in $Paths){
                if($obj.Contains('[') ){ Write-Host "$_" ; continue;  }
                $userobject = New-Object System.Security.Principal.NTAccount("$ENV:USERDOMAIN", "$username")
                $acl = Get-Acl -Path $obj
                #foreach ($aceToRemove in $acl.Access){
                #    $r= $acl.RemoveAccessRule($aceToRemove)
                #}
                
                $acl.SetAccessRuleProtection($false, $false)
                $acl.SetAccessRule($secobj_user_allow)
               
                $acl.SetOwner($userobject)

                Write-Verbose "Save the access rules for `"$obj`""
                # Save the access rules to disk:
                try{
                    $acl | Set-Acl $obj -ErrorAction Stop
                    [int]$per=[math]::Round($i / $object_count * 100)
                    Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete $per
                    #[void]$results.Add($obj)
                    $i++
                }catch{
                    Write-Host "Set-Acl ERROR `"$obj`" $_" -f Red
                }
            }
            Write-Progress -Activity 'Reset-AccessRights' -Complete
            Write-Verbose "$($results.Count) paths modified"
            $results
          }catch{
            Write-Error $_
          }
        }
    }
    

```


-------------------


## Get the code 


[RestrictDesktopPermissions on GitHub](https://github.com/arsscriptum/PowerShell.RestrictDesktopPermissions)