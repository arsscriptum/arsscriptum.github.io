---
layout: post
title:  "Save Online File using PowerShell HttpWebRequest"
summary: "Simple HTTP save with progress bar"
author: guillaume
date: '2022-10-20'
category: ['powershell','scripts', 'network']
tags: powershell, scripts, network
thumbnail: /assets/img/posts/simple-httpsave/1.png
keywords: network, powershell
usemathjax: false
permalink: /blog/simple-httpsave/

---

#### Save-OnlineFile 

Simple function to save a file locally with a progress bar. (Reading bytes per bytes)

```powershell
   function Save-OnlineFile{
	[CmdletBinding(SupportsShouldProcess)]
	param(
	    [Parameter(Mandatory=$True, Position=0)]
	    [string]$Url,
	    [Parameter(Mandatory=$True, Position=1)]
	    [Alias('Destination', 'p')]
	    [string]$Path    
	) 
	  try{
	    new-item -path $Path -ItemType 'File' -Force | Out-Null
	    remove-item -path $Path -Force | Out-Null

	    $Script:ProgressTitle = 'STATE: DOWNLOAD'
	    $uri = New-Object "System.Uri" "$Url"
	    $request = [System.Net.HttpWebRequest]::Create($Url)
	    $request.PreAuthenticate = $false
	    $request.Method = 'GET'

	    $request.Headers = New-Object System.Net.WebHeaderCollection
	    $request.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36')
	    $request.Timeout = ($TimeoutSec * 1000)
	    $request.set_Timeout(15000) #15 second timeout

	    $response = $request.GetResponse()

	    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
	    $totalLengthBytes = [System.Math]::Floor($response.get_ContentLength())
	    $responseStream = $response.GetResponseStream()
	    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $Path, Create
	    $buffer = new-object byte[] 10KB
	    $count = $responseStream.Read($buffer,0,$buffer.length)
	    $dlkb = 0
	    $downloadedBytes = $count
	    $script:steps = $totalLength

	    while ($count -gt 0){
	       $targetStream.Write($buffer, 0, $count)
	       $count = $responseStream.Read($buffer,0,$buffer.length)
	       $downloadedBytes = $downloadedBytes + $count
	       $dlkb = $([System.Math]::Floor($downloadedBytes/1024))
	       $msg = "Downloaded $dlkb Kb of $totalLength Kb"
	       $perc = (($downloadedBytes / $totalLengthBytes)*100)
	       if(($perc -gt 0)-And($perc -lt 100)){
	            Write-Progress -Activity $Script:ProgressTitle -Status "$msg" -PercentComplete $perc
	       }
	    }
	    Stop-AsciiProgressBar
	    $targetStream.Flush()
	    $targetStream.Close()
	    $targetStream.Dispose()
	    $responseStream.Dispose()
	  }catch{
	    Show-ExceptionDetails $_ -ShowStack
	  }finally{
	    Write-Progress -Activity $Script:ProgressTitle -Completed
	    Write-verbose "Downloaded $Url"
	  }
	}


```