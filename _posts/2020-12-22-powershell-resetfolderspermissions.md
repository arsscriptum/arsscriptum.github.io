---
layout: post
title:  "Reset Access Permissions..."
summary: "Reset/Fixing Folders Permissions for a Specified User"
author: guillaume
date: '2020-12-22'
category: ['powershell','scripts', 'useless']
tags: powershell, scripts, useless
thumbnail: /assets/img/posts/reset-acls-small.png
keywords: progress, powershell
usemathjax: false
permalink: /blog/powershell-resetfolders-acls/

---

### Reliable Tool to Quickly and easily give FullControl Permissions to a specified User </h3>


-------------------


This PowerShell scripts helps in quickly and easily reset access permissions. I wrote this today because of two reasons:



- Reddit user requiring help in fixing his access issues on his PC. [u/NegativelyMagnetic](https://www.reddit.com/u/NegativelyMagnetic) on a [Reddit post](https://www.reddit.com/r/PowerShell/comments/y6taqb/please_help_my_readwrite_access_permissions_are/). 
- Another [Reddit user](https://www.reddit.com/user/mudderfudden/) was asking [how to set the Desktop folder](https://www.reddit.com/r/PowerShell/comments/y56wqr/is_it_possible_to_set_the_desktop_folder_such/) such that only an Administrator can edit it's content, Still users have to be able to browse and use their shortcuts. 


For #2, I created a script to locate the desktop folder and change the permissions of its content so that it's admin-controlled.
During my TESTS, I needed a script to ```RESET the permissions on my desktop``` so that I can easily test and revert changes if required.
You can [read about it here](/blog/powershell-restrict-desktop-permissions/)

***That's when #1 was asking for a script to do exactly that*** : reset/revert/fix permissions on a group of folders.

I then wrote a bit of documentation, took some XAML template in my repo and glued together a GUI for the new tool.

<blockquote>
<p>I will talk about the subject in a separate post, but just so you know, I always have a *tasks list* and I had a task that was to
learn / play with the RichEditTextBox. I had some problems with it in the past and I needed to go over it and learn what I didn't know
in order to use it smootly.</p>
</blockquote>

That was my motive to use a RichEditTextBlock. A RichTextBox permits extended functionality in the text box like changing 
text color / font *per line*, changing the text size, etc... We will use that to log the operations of our app.

### UI => Show-ResetPermissionsDialog </h3>

This script is used to change the access control on a user's desktop folder so that only the administrator can modify it. The user can still open/execute shortcuts but not change the
content of the desktop folder.

#### Details 

The file receive the name of a local user as an argument. There is autocompletion to avoid bad entries. **The execution needs to be done as admin**
Then the function resolve the user desktop folder, will get the list of files and sub folders and change the ACLs, and remove the inheritance.


### Reset-AccessRights 

This function will revert the changes done by ```Set-RestrictedDesktopAccess``` by re-enabling inheritance and purging the added acls.


#### How To Use 

### to *test* before **-WhatIF**
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


<img class="card-img-top-restricted-60"
     src="/assets/img/posts/reset-acls-dialogs.png"
     alt="HowTo" />





- Browse and select the BASE directory from which the script will run 
- Enter the username that will be the owner and have full control over the objects that are processed 
- Select the listing of child objects. Those will be processed. Default is subfolders only. Select Files if you want to
   change the access rights over files as well.
   **NOTE 1** For Large folders, it is not recommended to select Files, Changing the ACLs over thousands of files will be very long.
   **NOTE 2** If your parent folders are configured properly with inheritance. After processed, the inheritance will be passed down to all subfolders
              and so you may not need to process the files, just the sub folders may be  sufficient 
- Step 4 **IMPORTANT** SIMULATION It is recommended that you check this box initially in order to test the objects that will be processed. 
- Step 5 GO 




-------------------


#### Quick Demo 


<img class="card-img-top-restricted-60"
     src="/assets/img/posts/reset-acls-demo.gif"
     alt="Demo" />




### Create a PowerShell GUI in XAML 

To quickly create and modify a powershell GUI, I personally use Visual Studio and create a dummy WPF project.

This lets me use the editor to visually create my GUI, then I can take the generated XAML and copy it in my script.

<center>
<img class="card-img-top-restricted-60"
     src="/assets/img/posts/reset-acls-guiedit.gif"
     alt="Demo" />

</center>


```xml
     
    <Window
                xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
                xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
                xmlns:local="clr-namespace:WpfApp10"
                Title="Reddit Support - Reset-Permissions" Height="463.632" Width="476.995" ResizeMode="NoResize" Topmost="True" WindowStartupLocation="CenterScreen">

        <Grid>
            <Image HorizontalAlignment="Left" Height="419" VerticalAlignment="Top" Width="469" Source="F:\Scripts\PowerShell.Reddit.Support\Reset-Permissions\img\BackGround.jpg" Margin="0,0,0,-58"/>
            <Label Name='Url' Content='by http://arsscriptum.github.io - For u/NegativelyMagnetic on Reddit' HorizontalAlignment="Left" Margin="10,70,0,0" VerticalAlignment="Top" Foreground="Gray" Cursor='Hand' ToolTip='by http://arsscriptum.github.io - For u/NegativelyMagnetic on Reddit'/>
            <TextBox Name='Path' HorizontalAlignment="Left" Height="23" Margin="69,10,0,0" TextWrapping="Wrap" Text="$env:APPDATA" VerticalAlignment="Top" Width="325"/>
            <Button Name='ResetPermissions' Content="Go" HorizontalAlignment="Left" Margin="361,378,0,0" VerticalAlignment="Top" Height="23" Width="75" RenderTransformOrigin="0.161,14.528"/>
            <RichTextBox Name='OutputStream' HorizontalAlignment="Left" Height="239" Margin="10,102,0,0" VerticalAlignment="Top" Width="440">
                <RichTextBox.Resources>
                    <Style TargetType="{x:Type Paragraph}">
                        <Setter Property="Margin" Value="0" />
                    </Style>
                </RichTextBox.Resources>
                <FlowDocument>
                    <Paragraph>
                        <!-- <Run Text="RichTextBox"/> -->
                    </Paragraph>
                </FlowDocument>
            </RichTextBox>
            <Label x:Name="labelpath" Content="Start Path" HorizontalAlignment="Left" Margin="3,9,0,0" VerticalAlignment="Top"/>
            <Button x:Name="browse" Content="..." HorizontalAlignment="Left" Margin="404,10,0,0" VerticalAlignment="Top" Width="32" Height="25"/>
            <CheckBox x:Name="whatif_check" Content="WhatIf: Don't change permissions. Just list actions" HorizontalAlignment="Left" Margin="10,390,0,0" VerticalAlignment="Top" Width="310" Height="25"/>
            <Label x:Name="owner_label" Content="Owner" HorizontalAlignment="Left" Margin="3,40,0,0" VerticalAlignment="Top"/>
            <TextBox x:Name='Owner' HorizontalAlignment="Left" Height="23" Margin="69,41,0,0" TextWrapping="Wrap" Text="$env:APPDATA" VerticalAlignment="Top" Width="325"/>
            <CheckBox x:Name="check_dir" IsChecked="True" Content="Process Sub-directories" HorizontalAlignment="Left" Margin="10,364,0,0" VerticalAlignment="Top"/>
            <CheckBox x:Name="check_files" IsChecked="False" Content="Process Files (childs)" HorizontalAlignment="Left" Margin="178,364,0,0" VerticalAlignment="Top"/>
        </Grid>
    </Window>

```

---------------------------------------------------------------------------------------------------------

#### Reset-AccessRights 

This is how we change the folders ACLS. Resetting the owner at the same time:




```powershell

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('p', 'f','File')]
        [string]$BasePath,
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
        [string]$Owner,
        [parameter(Mandatory=$False)]
        [bool]$Simulation,
        [parameter(Mandatory=$False)]
        [bool]$Directories,
        [parameter(Mandatory=$False)]
        [bool]$Files
    )

    #requires -runasadministrator
    $is_admin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) 
    if($False -eq $is_admin)   { throw "Administrator privileges required" } 
    
    loghlt "[Reset-DirectoryAcl] Resetting ACLs for owner => $Owner"
    loghlt "[Reset-DirectoryAcl] From base path           => $BasePath"
    loghlt "[Reset-DirectoryAcl] Sub directories          => $Directories"
    loghlt "[Reset-DirectoryAcl] All subdirectories files => $Files"
    loghlt "Listing ... "
    $Paths = (gci -Path $BasePath -Directory:$Directories -File:$Files).Fullname
    $Paths += $BasePath
    $object_count = $Paths.Count
    logerr  "$object_count objects to process..."
 
    
    $username = (Get-LocalUser).Name -replace '(.*\s.*)',"'`$1'" | Where-Object { $_ -match "$Owner"}
    Write-Verbose "Reset-AccessRights for owner $Owner. Num $object_count paths"
    logttt "Reset-AccessRights for owner $Owner. Num $object_count paths"
    
    try{
        $usr_allow  = "$ENV:USERDOMAIN\$username", 'FullControl'  , "none, none","none","Allow"
        $secobj_user_allow  = New-Object System.Security.AccessControl.FileSystemAccessRule $usr_allow 
        $i = 0
        Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete 0
        if($Null -eq $secobj_user_allow)    { throw "Error on FileSystemAccessRule creation $usr_allow" }
        [system.collections.arraylist]$results = [system.collections.arraylist]::new()
        ForEach($obj in $Paths){
            if($obj.Contains('[') ){ Write-Host "$_" ; continue;  }
            $userobject = New-Object System.Security.Principal.NTAccount("$ENV:USERDOMAIN", "$username")

            # ===============================================================
            # BELOW - THIS IS THE MEAT OF THE SCRIPT - WHERE THE SHIT HAPPENS
            # ===============================================================

            # Fetch the ACL for the object listed.
            $acl = Get-Acl -Path $obj

            # Sets or removes protection of the access rules: Enables Inheritance (second argument is ignored if first is False)
            $acl.SetAccessRuleProtection($false, $false)

            # We SET a ACL for the specified user: FULL CONTROL
            $acl.SetAccessRule($secobj_user_allow)

            # IMPORTANT NOTE: Since we enabled inheritance, we don't add anymore ACLs to this oject and rely on 
            # the parent rights. I want this script to apply minimal privileges changes possile for evey objects.
            # If the inheritance is setup properly, this is the best way to "RESET" the access rights.
           
            # Lastly,  make sure that the owner is set correctly.
            $acl.SetOwner($userobject)

            # ================================================================
            # ABOVE -- THSI IS THE MEAT OF THE SCRIPT - WHERE THE SHIT HAPPENS
            # ================================================================

            # Save the access rules to disk:
            Write-Verbose "Save the access rules for `"$obj`""

            try{
                if($Simulation){
                    loghlt "$obj"
                }else{
                    $acl | Set-Acl $obj -ErrorAction Stop
                    [int]$per=[math]::Round($i / $object_count * 100)
                    Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete $per
                    lognrm "$obj"
                    $i++
                }
            }catch{
                logerr "Set-Acl ERROR `"$obj`" $_"
            }
        }
        Write-Progress -Activity 'Reset-AccessRights' -Complete
        logscs "$($results.Count) paths modified"
        
        $results
      }catch{
        Write-Error $_
      }
    

```

-------------------

#### Using a **System.Windows.Controls.RichTextBox** as a nice Logging Window. 



```powershell

    function Write-RichTextBox {
    [CmdletBinding(SupportsShouldProcess)]
        Param (
            [parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
            [System.Windows.Controls.RichTextBox]$RichTextBoxControl,
            [parameter(Position=1, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
            [String]$Text,
            [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [String]$FontStyle = 'Normal',
            [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [String]$FontWeight = 'Normal',
            [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [String]$FontSize= '12',
            [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [String]$ForeGroundColor = 'Black',
            [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [String]$BackGroundColor = 'White',
            [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [Switch]$NewLine
        )
        $ParamOptions = $PSBoundParameters
        $RichTextRange = New-Object System.Windows.Documents.TextRange(<#$RichTextBoxControl.Document.ContentStart#>$RichTextBoxControl.Document.ContentEnd, $RichTextBoxControl.Document.ContentEnd)
        if ($ParamOptions.ContainsKey('NewLine')) {
            $RichTextRange.Text = "`n$Text"
        }
        else  {
            $RichTextRange.Text = $Text
        }

        $Defaults = @{ForeGroundColor='Black';BackGroundColor='White';FontSize='12'; }
        foreach ($Key in $Defaults.Keys) {
            if ($ParamOptions.Keys -notcontains $Key) {
                $ParamOptions.Add($Key, $Defaults[$Key])
            }
        }  

        $AllParameters = $ParamOptions.Keys | Where-Object {@('RichTextBoxControl','Text','NewLine') -notcontains $_}
        foreach ($SelectedParam in $AllParameters) {
            if ($SelectedParam -eq 'ForeGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::ForegroundProperty}
            elseif ($SelectedParam -eq 'BackGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::BackgroundProperty}
            elseif ($SelectedParam -eq 'FontSize') {$TextElement = [System.Windows.Documents.TextElement]::FontSizeProperty}
            elseif ($SelectedParam -eq 'FontStyle') {$TextElement = [System.Windows.Documents.TextElement]::FontStyleProperty}
            elseif ($SelectedParam -eq 'FontWeight') {$TextElement = [System.Windows.Documents.TextElement]::FontWeightProperty}
            $RichTextRange.ApplyPropertyValue($TextElement, $ParamOptions[$SelectedParam])
        }
    }


    Function Out-LogMessage{
        [CmdletBinding(SupportsShouldProcess)]
        Param (
            [parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
            [String]$Message,
            [Parameter(Mandatory=$False,Position=1)]
            [ValidateSet('LogError','LogSuccess','LogHighlight','LogNormal','LogTitle')]
            [string]$Type='LogNormal',
            [parameter(Mandatory=$false)]
            [Alias('f')]
            [string]$ForeGround = 'Gray',
            [parameter(Mandatory=$false)]
            [Alias('n')]
            [switch]$NoNewLine
        )
        Write-Verbose "Out-LogMessage $Message $Type"
        $AddNewLine = $True
        if($NoNewLine) { $AddNewLine = $False } 

        switch ($Type)
        {
            "LogError"      { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '12' -Foreground Red         -Background Yellow          -FontWeight 'Bold'       -NewLine:$AddNewLine  } 
            "LogSuccess"    { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '14' -Foreground White       -Background Green           -FontStyle 'Italic'      -NewLine:$AddNewLine  } 
            "LogHighlight"  { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '10' -Foreground DarkOrange  -FontWeight 'Bold'          -NewLine:$AddNewLine                           } 
            "LogNormal"     { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '10' -Foreground Teal        -NewLine:$AddNewLine                                                       } 
            "LogTitle"      { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '16' -Foreground Yellow      -Background Fuchsia         -FontWeight 'Bold'       -NewLine:$AddNewLine  } 
        }
    }

```

---------------------------------------------------------------------------------------------------------


## Get the code 


[ResetFoldersPermissions on GitHub](https://github.com/arsscriptum/PowerShell.ResetFoldersPermissions)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**