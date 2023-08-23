---
layout: post
title:  "Save a Reddit Video using PowerShell"
summary: "Retriving the download url of a video and download it using powershell cmdlet"
author: guillaume
date: '2022-11-10'
category: ['powershell','scripts', 'video','reddit']
tags: powershell, scripts, video, reddit
thumbnail: /assets/img/posts/reddit-video/1.png
keywords: video, powershell, reddit
usemathjax: false
permalink: /blog/powershell-save-reddit-video/

---

### Save a Reddit Video using PowerShell </h3>

Save a Reddit Video using PowerShell script. Also contains a native, custom progress bar implementation for dos-minded people amd systray notifier.


---------------------------------------------------------------------------------------------------------


#### How To Use 

1. On Reddit, if you find a page containing a video, just grab the page URL (*not the video url, this is automatic*) and pass it to the function
2. Copy the Url of the post, pass it to the function.


---------------------------------------------------------------------------------------------------------


![HowTo](https://raw.githubusercontent.com/arsscriptum/PowerShell.SaveRedditVideo/main/doc/s2.gif)
![HowTo](https://raw.githubusercontent.com/arsscriptum/PowerShell.SaveRedditVideo/main/doc/demo.gif)

---------------------------------------------------------------------------------------------------------


```
    Save-RedditVideo.ps1 -Url "https://www.reddit.com/r/ukraine/comments/yqwngl/volodymyr_zelenskyy_official_nov_9th_2022_about/"
```


---------------------------------------------------------------



 ####  Get-RedditVideoUrl 


```powershell

    function Get-RedditVideoUrl{
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
            [string]$Url  
        )

        try{
            $Null =  Add-Type -AssemblyName System.webURL -ErrorAction Stop | Out-Null    
        }catch{}
        

       try{    
            $urlToEncode = $Url
            $encodedURL = [System.Web.HttpUtility]::UrlEncode($urlToEncode) 

            Write-Verbose "The encoded url is: $encodedURL"

            #Encode URL code ends here

            $RequestUrl = "https://www.redditsave.com/info?url=$encodedURL"

            Write-Verbose "Invoke-RestMethod -Uri `"$RequestUrl`" -Method 'GET'"
            $Content = Invoke-RestMethod -Uri "$RequestUrl" -Method 'GET'

            $i = $Content.IndexOf('"https://sd.redditsave.com/download.php')
            $j = $Content.IndexOf('"',$i+1)
            $l = $j-$i
            $RequestUrl = $Content.Substring($i+1, $l-1)

            Write-Output "$RequestUrl"
        }catch{
            Show-ExceptionDetails $_ -ShowStack
        }
    }


```

---------------------------------------------------------------------------------------------------------
 ####  Save-RedditVideo 


```powershell

    function Save-RedditVideo{
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
            [string]$Url,
            [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Destination Directory where the files are saved", Position=1)]
            [string]$DestinationPath,
            [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="If set, will open the file afer download")]
            [switch]$OpenAfterDownload          
        )
    <#
    .SYNOPSIS
        Retrieve the download URL for a REDDIT video and download the file
    .DESCRIPTION
        Retrieve the download URL for a REDDIT video and download the file for viewing pleasure
    .PARAMETER Url
        The Url of the page where the video is located
    .PARAMETER DestinationPath
        Destination Directory where the files are saved
    .PARAMETER OpenAfterDownload
        If set, will open the file afer download

    .EXAMPLE
        Save-RedditVideo.ps1 -Url "https://www.reddit.com/r/ukraine/comments/yqwngl/volodymyr_zelenskyy_official_nov_9th_2022_about/"


    .NOTES
        Author: Guillaume Plante
        Last Updated: October 2022
    #>
        try{
            $Null =  Add-Type -AssemblyName System.webURL -ErrorAction Stop | Out-Null    
        }catch{}
        

       try{    
            if($PSBoundParameters.ContainsKey("DestinationPath") -eq $False){
                $MyVideos = [environment]::getfolderpath("myvideos")
                $RedditVideoPath = Join-Path $MyVideos 'reddit'
                if(-not(Test-Path -Path $RedditVideoPath -PathType Container)){
                    $Null = New-Item -Path $RedditVideoPath -ItemType "Directory" -Force -ErrorAction Ignore 
                }
                $DestinationPath = $RedditVideoPath

            }else{
                if( -not ( Test-Path -Path $DestinationPath -PathType Container)) { throw "DestinationPath argument does not exists ; "}
            }

            [string]$DestinationFile = New-RandomFilename -Path $DestinationPath  -Extension 'mp4'
            [Uri]$ParsedUrlObject = $Url
            $sgm_list = $ParsedUrlObject.Segments
            $sgm_list_count = $sgm_list.Count
            if($sgm_list_count -gt 0){
                $UrlFileName = $sgm_list[$sgm_list_count-1] + '.mp4'
                $UrlFileName = $UrlFileName.Replace('/','')
                $DestinationFile = Join-Path $DestinationPath $UrlFileName
            }

            $DownloadVideoUrl = Get-RedditVideoUrl $Url
            $WgetExe          = Get-WGetExecutable

            Write-Verbose "DestinationPath  : $DestinationPath"
            Write-Verbose "DestinationFile  : $DestinationFile"
            Write-Verbose "DownloadVideoUrl : $DownloadVideoUrl"

            Write-Host -n -f DarkRed "[RedditVideo] " ; Write-Host -f DarkYellow "Please wait...."

            #Save-OnlineFileWithProgress $DownloadVideoUrl $DestinationFile

            $Title = "Download Completed"
            $IconPath = Join-Path "$PSScriptRoot\ico" "download2.ico"

            Show-SystemTrayNotification "Saved $DestinationFile" $Title $IconPath -Duration $Duration

           
            if($OpenAfterDownload){
                start "$DestinationFile"
            }
            "$DestinationFile"
        }catch{
            Show-ExceptionDetails $_ -ShowStack
        }
    }
```

---------------------------------------------------------------------------------------------------------

 ####  Write-AsciiProgressBar 


Native version of this litle project: https://github.com/arsscriptum/PowerShell.CustomProgressBar


---------------------------------------------------------------------------------------------------------

 ####  SystemTrayNotifier Popup  


From this litle project:  https://github.com/arsscriptum/PowerShell.SystemTrayNotifier

---------------------------------------------------------------------------------------------------------



### Get the Code

[SaveRedditVideo on GitHub](https://github.com/arsscriptum/PowerShell.SaveRedditVideo)