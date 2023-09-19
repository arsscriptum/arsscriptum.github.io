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

        begin{
         
            [System.Collections.ArrayList]$LibObjects = [System.Collections.ArrayList]::new()
            $CurrPath = "$PSScriptRoot"
            $LibPath = "$CurrPath\lib\$($PSVersionTable.PSEdition)"
            $Dlls = (gci -Path $LibPath -Filter '*.dll').FullName
            ForEach($lib in $Dlls){
                $libObj = add-type -Path $lib -Passthru
                [void]$LibObjects.Add($libObj)
            }

        }
        process{
            try{
                $urlToEncode = $Url
                
                $encodedURL = [System.Web.HttpUtility]::UrlEncode($urlToEncode) 

                Write-Verbose "The encoded url is: $encodedURL"

                #Encode URL code ends here

                $RequestUrl = "https://www.redditsave.com/info?url=$encodedURL"

                Write-Verbose "Invoke-RestMethod -Uri `"$RequestUrl`" -Method 'GET'"

                $prevProgressPreference = $global:ProgressPreference
                $global:ProgressPreference = 'SilentlyContinue'
                $webreq = Invoke-WebRequest -Uri "$RequestUrl" -Method 'GET' -ErrorAction Stop
                $global:ProgressPreference = $prevProgressPreference
                
                $StatusCode = $webreq.StatusCode
                if($StatusCode -ne 200){
                    throw "Invalid request response ($StatusCode)"
                }
        
                [string]$Content = $webreq.Content

                $HtmlDoc = New-Object HtmlAgilityPack.HtmlDocument
                $HtmlDoc.LoadHtml($Content)
                $HtmlNode = $HtmlDoc.DocumentNode



                $DownloadInfo = $HtmlNode.SelectNodes("//div[@class='download-info']")
                if($Null -eq $DownloadInfo) {throw "download info not found"}
                $OuterHtml = $DownloadInfo.OuterHtml
                $Index = $OuterHtml.IndexOf('https://sd.rapidsave.com/download.php')
                $Index2 = $OuterHtml.IndexOf('>',$Index)
                $Len = $Index2-$Index
                $DownloadUrl = $OuterHtml.Substring($Index,$Len)
                $DownloadUrl = $DownloadUrl.TrimEnd('"')
                $DownloadUrl
            }catch{
                Show-ExceptionDetails $_ -ShowStack
            }
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
        $Null =  Add-Type -AssemblyName System.webURL -ErrorAction Stop | Out-Null    
    }catch{}
    

   try{    
        if(! $PSCmdlet.ShouldProcess("$Url")){
            $DownloadVideoUrl = Get-RedditVideoUrl_V2 $Url
            Write-Host -n -f DarkRed "`n[WHATIF Save-RedditVideo] " ; Write-Host -f DarkYellow "Would download $DownloadVideoUrl"
            return
        }

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

        $DownloadVideoUrl = Get-RedditVideoUrl_V2 $Url

        Write-Verbose "DestinationPath  : $DestinationPath"
        Write-Verbose "DestinationFile  : $DestinationFile"
        Write-Verbose "DownloadVideoUrl : $DownloadVideoUrl"

        Write-Host -n -f DarkRed "[Save-RedditVideo] " ; Write-Host -f DarkYellow "Please wait...."

        $download_stop_watch = [System.Diagnostics.Stopwatch]::StartNew()
        Save-OnlineFileWithProgress_V2 $DownloadVideoUrl $DestinationFile
        [timespan]$ts =  $download_stop_watch.Elapsed
        if($ts.Ticks -gt 0){
            $ElapsedTimeStr = "Downloaded in {0:mm:ss}" -f ([datetime]$ts.Ticks)
        }

        Write-Host -n -f DarkRed "`n[Save-RedditVideo] " ; Write-Host -f DarkYellow "$ElapsedTimeStr"

        #$Title = $ElapsedTimeStr
        #$IconPath = Get-ToolsModuleDownloadIconPath

        #Show-SystemTrayNotification "Saved $DestinationFile" $Title $IconPath -Duration $Duration
     
       
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

<br>
<center>
<img src="https://arsscriptum.github.io/assets/img/posts/reddit-video/s2.gif" alt="table" />
</center>
<br>

---------------------------------------------------------------------------------------------------------

<br>
<center>
<img src="https://arsscriptum.github.io/assets/img/posts/reddit-video/demo.gif" alt="table" />
</center>
<br>

---------------------------------------------------------------------------------------------------------

<br>
<center>
<img src="https://arsscriptum.github.io/assets/img/posts/reddit-video/demo2.gif" alt="table" />
</center>
<br>


---------------------------------------------------------------------------------------------------------

### Write-AsciiProgressBar 

Native version of this litle project: [https://github.com/arsscriptum/PowerShell.CustomProgressBar](https://github.com/arsscriptum/PowerShell.CustomProgressBar)


---------------------------------------------------------------------------------------------------------

### SystemTrayNotifier Popup  

From this litle project:  [https://github.com/arsscriptum/PowerShell.SystemTrayNotifier](https://github.com/arsscriptum/PowerShell.SystemTrayNotifier)

---------------------------------------------------------------------------------------------------------


### Get the Code

[SaveRedditVideo on GitHub](https://github.com/arsscriptum/PowerShell.SaveRedditVideo)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**