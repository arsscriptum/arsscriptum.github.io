---
layout: post
title:  "PowerShell Web Scrapper"
summary: "Using PowerShell to lit and download files from the NirSoft website"
author: guillaume
date: '2023-10-05'
category: ['powershell','scripts', 'scrapper','webscrapper','web']
tags: powershell, scripts, scrapper, webscrapper, web
thumbnail: /assets/img/posts/webscrapper/main.png
keywords: powershell, scripts, scrapper, webscrapper, web
usemathjax: false
permalink: /blog/webscrapper/

---


## Overview

Web scraping is the process of using bots to extract content and data from a website. Unlike screen scraping, which only copies pixels displayed onscreen, web scraping extracts underlying HTML code and, with it, links and data stored in a database. The scraper can then replicate entire website content elsewhere, or the data can be used to generate a list of files to be downloaded later on.

## NirSoft

[NirSoft](https://www.nirsoft.net/) web site provides a  collection of small and useful [freeware utilities](https://www.nirsoft.net/utils/index.html)

Here's some examples of what you can find in NirSoft Web site:

 - Password Recovery Utilities
 - Network Monitoring Tools
 - Internet Related Utilities
 - MS-Outlook Tools
 - Command-Line Utilities
 - Desktop Utilities
 - System Tools


## Web Scrapping the NirSoft applications

Some of the NirSoft utilities I use on the regular and as a small project, wanted to make a script toget the list of all NirSoft utilities and to download them to a local drive.


### Get Application Page Links

First we need to get evey application page links. Each application page then contains the links for the files to be downloaded. So first, get the application pages. 

In order to get the links, we need to parse some HTML, in any other cases, I would recommend using the powerful [Html Agility Pack](https://html-agility-pack.net/) but for minor parsing like this case, where we only need to get the links from a page, we can use the basic parsing functionalities of the ```Invoke-WebRequest``` cmdlet to get the links of the download page. See when you get the return object from the ```Invoke-WebRequest``` call, you can the folloing properties:

```csv
 BaseResponse      Property   System.Net.Http.HttpResponseMessage BaseResponse {get;set;}
 Content           Property   string Content {get;}
 Encoding          Property   System.Text.Encoding Encoding {get;}
 Headers           Property   System.Collections.Generic.Dictionary[string,System.Collections.Generic.IEnumerable[strin…
 Images            Property   Microsoft.PowerShell.Commands.WebCmdletElementCollection Images {get;}
 InputFields       Property   Microsoft.PowerShell.Commands.WebCmdletElementCollection InputFields {get;}
 Links             Property   Microsoft.PowerShell.Commands.WebCmdletElementCollection Links {get;}
```

And here we want the ***links*** like this ```$Links = $WebResponse.Links | Select href```

Code:

```powershell


  function Get-NirSoftLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, HelpMessage="max")]
        [int]$Max=0
    )

    [string]$Url = "https://www.nirsoft.net/utils/index.html"
    
    $prevProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'
    $WebResponse = Invoke-WebRequest  $Url
    $global:ProgressPreference = $prevProgressPreference
        
    
    $StatusCode = $WebResponse.StatusCode
    if($StatusCode -ne 200){
        throw "Invalid request response ($StatusCode)"
    }

    $PreParsedLinks = [System.Collections.ArrayList]::new()
    $PostParsedLinks = [System.Collections.ArrayList]::new()
    $Links = $WebResponse.Links | Select href
    ForEach($l in $Links.href){
        if(($l -match 'html')-And($l -notmatch '\.\.')-And($l -notmatch '/')){
            $Null = $PreParsedLinks.Add($l)
            if($Max -gt 0){
                if(($PreParsedLinks.Count) -ge $Max){
                    break;
                }
            }
        }
    } 
    return $PreParsedLinks
  }


```

### Results

This returns something like this:

```csv
	web_browser_password.html
	external_drive_password_recovery.html
	internet_explorer_password.html
	passwordfox.html
	chromepass.html
	wireless_key.html
	outlook_accounts_view.html
	windows_mail_password_recovery.html
```


## Process the download links

Next, we want to process the application page links and get the download links. So for each page we got above, we create a link like this: ```[string]$RequestedUrl = "https://www.nirsoft.net/utils/" + $l``` then we request the page and parse the links again. 

```powershell 
  [string]$RequestedUrl = "https://www.nirsoft.net/utils/" + "qr_code_generator.html"
  $LinksRequestResponse = Invoke-WebRequest  $RequestedUrl
  $LinksRequestResponse.Links | Select href

	href
	----
	simplecodegenerator.zip
	trans/simplecodegenerator_arabic.zip
	trans/simplecodegenerator_dutch.zip
	trans/simplecodegenerator_turkish.zip
```

As you can see we get the application links. The links starting with ```trans``` are the translated packages, I don't care about those. Maybe you do, if so change the code accordingly. Here's the process function.
This function will get the download links for every app and create a ```PSObject``` with the name, link and and file type (x86 or x64). It will then save all this information in a **JSON formated file** in the *db directory*


```powershell

  function Invoke-ProcessNirSoftLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position = 0, HelpMessage="exp")]
        [System.Collections.ArrayList]$Links,
        [Parameter(Mandatory=$true, Position = 1, HelpMessage="OutFile")]
        [String]$OutFile
    )
    try{

        $Null = Remove-Item -Path $OutFile -Force -ErrorAction Ignore
        $Null = New-Item -Path $OutFile -ItemType File -Force -ErrorAction Ignore
        
        [System.Collections.ArrayList]$AllLinks = [System.Collections.ArrayList]::new()

        Show-MsgBoxProgress
        $CurrId=0
        $LinksCount = $Links.Count
        [string]$BaseUrl = "https://www.nirsoft.net/utils/"
        [string]$RequestedUrl = ""
       
        [int]$Counter = 1
        ForEach($l in $Links){
            $Counter++
           
            if($Script:OperationCancelled -eq $True){ 
                $JsonData = $AllLinks | ConvertTo-Json
                Set-Content -PAth $OutFile -Value $JsonData
                return $OutFile
            }
            [string]$RequestedUrl = "https://www.nirsoft.net/utils/" + $l
            Write-Verbose "Getting links from $RequestedUrl " 
            

            $prevProgressPreference = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
            $LinksRequestResponse = Invoke-WebRequest  $RequestedUrl -ErrorAction Stop
            $global:ProgressPreference = $prevProgressPreference
                        
            
            $StatusCode = $LinksRequestResponse.StatusCode
            $msg = "Processed $Counter out of $LinksCount links"
            $perc = [math]::Round( (($Counter / $LinksCount)*100))
            
            if($perc -le 1){ $perc = 1 }
            if($perc -ge 99){ $perc = 100 } 
            
            $Script:labelProgress.Content = $msg 
            $Script:pbStatus.Value = $perc
            $Null = [System.Windows.Forms.Application]::DoEvents()  | Out-Null
            
            if($StatusCode -ne 200){
                throw "Invalid request response ($StatusCode)"
            }
            $htmldata = $LinksRequestResponse.Content
            $InnerLinks = $LinksRequestResponse.Links | Select href
            

            ForEach($l in $InnerLinks.href){
                if(($l -match '\.zip')-Or($l -match '\.exe')){
                    $firstChar = $l[0]
                    $fullLink = $BaseUrl + $l
                    if($firstChar -eq '/'){
                        $fullLink =  "https://www.nirsoft.net" + $l
                    }
                    # $r = Test-NirsoftUrl -Url $fullLink
                    if($fullLink -notmatch 'trans'){
                        Write-Verbose "ProcessLinks => Adding $fullLink "
                      
                        $Type = 'x86'
                        if($fulllink -match 'x64') { $Type = 'x64' }
                        [uri]$u = $RequestedUrl
                        $Filename = $u.Segments[$u.Segments.Count-1]
                        $Filename = $Filename.substring(0,($Filename.IndexOf('.')))
                        $o = [PsCustomObject]@{
                            Name = $Filename
                            Type = $Type 
                            Url  = $fullLink
                        }
                        [void]$AllLinks.Add($o)
                    }

                }
            } 
            
        } 

        $Script:Window.Close()
        
        $JsonData = $AllLinks | ConvertTo-Json
        Set-Content -PAth $OutFile -Value $JsonData
        $OutFile
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
  }
```


## Save the files

We then need to go through the list of links in the *json file* and download every file locally. This is a regular file download, it can be done in multiple different ways.

In the file [Save-NirSoftFiles.ps1](https://github.com/arsscriptum/PowerShell.NirSoft/blob/master/scripts/Save-NirSoftFiles.ps1) , I have implemented a download function using ```[System.Net.HttpWebRequest]``` *dot NET* class. You can also download the files *sequentially* (one after the other) or in parallel, using *JOBS*

```powershell

  function Save-AllNirSoftLinks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Parallel
    )

    $RootFolder         = (Resolve-Path -Path "$PSScriptRoot\..").Path
    $DbPath             = Join-Path $RootFolder 'db'
    $ScriptsPath        = Join-Path $RootFolder 'scripts'
    $SavedDataPath      = Join-Path $RootFolder 'saved'
    $DownloadLinksJson  = Join-Path $DbPath 'download_links.json'


    $Null = Remove-Item -Path $SavedDataPath -Recurse -Force -ErrorAction Ignore
    $Null = New-Item -Path $SavedDataPath -ItemType Directory -Force -ErrorAction Ignore
        
    Show-MsgBoxProgress

    $Data = Get-Content -Path $DownloadLinksJson | ConvertFrom-Json
    [uint32]$DataCount = $Data.Count
    [uint32]$count = 0
    ForEach($item in $Data){

      if($Script:OperationCancelled -eq $True){ 
        $Script:Window.Close()
        return
      }

      $count++
      $name = $item.Name
      $link = $item.Url
      $type = $item.Type
      
      $newpath = Join-Path $SavedDataPath $name
      $newpath = Join-Path $newpath $type
      
      $Null = New-Item -Path $newpath -ItemType Directory -Force -ErrorAction Ignore
      
      [uri]$u = $link
      $Filename = $u.Segments[$u.Segments.Count-1]
    
      $msg = "Processed $count out of $DataCount links"
      $perc = [math]::Round( (($count / $DataCount)*100))
            
      if($perc -le 1){ $perc = 1 }
      if($perc -ge 99){ $perc = 100 } 
            
      $Script:labelProgress.Content = $msg 
      $Script:pbStatus.Value = $perc
      $Null = [System.Windows.Forms.Application]::DoEvents()  | Out-Null
            

      Get-OnlineNirsoftFile -Url $link -DestinationPath $newpath -Parallel:$Parallel
  
    }
    $Script:Window.Close()
        
    if($Parallel -eq $True){
      ForEach($job_id in $Script:AllJobs){
          Start-Sleep -Milliseconds 20
          $job_data = Get-Job -Id $job_id
          $status = $job_data.State
          if($status -eq 'Completed'){
            Write-Host "Job $job_id completed!"
            get-job -Id $job_id | Remove-Job -Force
          }
        }
    }
  }



	[System.Collections.ArrayList]$Script:AllJobs = [System.Collections.ArrayList]::new()

	function Save-NirsoftFile{

	    [CmdletBinding(SupportsShouldProcess)]
	    param(
	        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="exp")]
	        [Alias("u")]
	        [string]$Url,
	        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="DestinationPath")]
	        [Alias("d")]
	        [string]$DestinationPath
	    )


	  try{

	    [Uri]$Val = $Url;
	    $HttpHost = $Val.Host
	    $HttpPathAndQuery = $Val.PathAndQuery
	    $FullPathAndQuery = $HttpHost +$HttpPathAndQuery
	    $Name = $Val.Segments[$Val.Segments.Count-1]
	    $DestinationFilePath = Join-Path $DestinationPath $Name
	    $HttpReferrer = $HttpHost
	    
	    Write-verbose "Downloading to $DestinationFilePath"
	    $Script:ProgressTitle = 'STATE: DOWNLOAD'
	    $uri = New-Object "System.Uri" "$Url"
	    $request = [System.Net.HttpWebRequest]::Create($Url)
	    $request.PreAuthenticate = $false
	    $request.Method = 'GET'

	    $request.Headers.Add('sec-ch-ua', '" Not A;Brand";v="99", "Chromium";v="99", "Google Chrome";v="99"')
	    $request.Headers.Add('sec-ch-ua-mobile', '?0')
	    $request.Headers.Add('sec-ch-ua-platform', "Windows")
	    $request.Headers.Add('Sec-Fetch-Site', 'same-site')
	    $request.Headers.Add('Sec-Fetch-Mode' ,'navigate')
	    $request.Headers.Add('Sec-Fetch-Dest','document')
	    $request.Headers.Add('Upgrade-Insecure-Requests', '1')
	    $request.Headers.Add('User-Agent','Automated PowerShell Script')

	    $request.Referer = $HttpReferrer
	    $request.Headers.Add('Referer' , $HttpReferrer)

	    $request.Headers.Add('Accept-Encoding', 'gzip, deflate, br')
	    $request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'

	    $request.KeepAlive = $true
	    $request.Timeout = ($TimeoutSec * 1000)

	    $request.set_Timeout(15000) #15 second timeout

	    $response = $request.GetResponse()

	    $totalLengthKb = [System.Math]::Floor($response.get_ContentLength()/1024)
	    $totalLengthMb = [System.Math]::Floor($response.get_ContentLength()/1024/1024)
	    $totalLengthBytes = [System.Math]::Floor($response.get_ContentLength())
	    $responseStream = $response.GetResponseStream()
	    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $DestinationFilePath, Create
	    $buffer = new-object byte[] 10KB
	    $count = $responseStream.Read($buffer,0,$buffer.length)
	    $dlkb = 0
	    $downloadedBytes = $count
	    $script:steps = $totalLengthKb
	    while ($count -gt 0){
	       $targetStream.Write($buffer, 0, $count)
	       $count = $responseStream.Read($buffer,0,$buffer.length)
	       $downloadedBytes = $downloadedBytes + $count
	       $dlkb = $([System.Math]::Floor($downloadedBytes/1024))
	       $dlmb = $([System.Math]::Floor($downloadedBytes/1024/1024))
	       $msg = "Downloaded $dlmb MB of $totalLengthMb MB"
	       $perc = (($downloadedBytes / $totalLengthBytes)*100)
	       #if(($perc -gt 0)-And($perc -lt 100)){
	        # Write-Progress -Activity $Script:ProgressTitle -Status $msg -PercentComplete $perc 
	       #}
	    }

	    $targetStream.Flush()
	    $targetStream.Close()
	    $targetStream.Dispose()
	    $responseStream.Dispose()
	  }catch{
	    throw $_

	  }finally{
	    #Write-Progress -Activity $Script:ProgressTitle -Completed
	    Write-verbose "Downloaded $Url"
	  }
	}




	$ParallelScript = {
	  param($Url,$DestinationPath)
	    
	  try{
	    [Uri]$Val = $Url;
	    $HttpHost = $Val.Host
	    $HttpPathAndQuery = $Val.PathAndQuery
	    $FullPathAndQuery = $HttpHost +$HttpPathAndQuery
	    $Name = $Val.Segments[$Val.Segments.Count-1]
	    $DestinationFilePath = Join-Path $DestinationPath $Name
	    $HttpReferrer = $HttpHost
	    
	    Write-verbose "Downloading to $DestinationFilePath"
	    $Script:ProgressTitle = 'STATE: DOWNLOAD'
	    $uri = New-Object "System.Uri" "$Url"
	    $request = [System.Net.HttpWebRequest]::Create($Url)
	    $request.PreAuthenticate = $false
	    $request.Method = 'GET'

	    $request.Headers.Add('sec-ch-ua', '" Not A;Brand";v="99", "Chromium";v="99", "Google Chrome";v="99"')
	    $request.Headers.Add('sec-ch-ua-mobile', '?0')
	    $request.Headers.Add('sec-ch-ua-platform', "Windows")
	    $request.Headers.Add('Sec-Fetch-Site', 'same-site')
	    $request.Headers.Add('Sec-Fetch-Mode' ,'navigate')
	    $request.Headers.Add('Sec-Fetch-Dest','document')
	    $request.Headers.Add('Upgrade-Insecure-Requests', '1')
	    $request.Headers.Add('User-Agent','Automated PowerShell Script')

	    $request.Referer = $HttpReferrer
	    $request.Headers.Add('Referer' , $HttpReferrer)

	    $request.Headers.Add('Accept-Encoding', 'gzip, deflate, br')
	    $request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'

	    $request.KeepAlive = $true
	    $request.Timeout = ($TimeoutSec * 1000)

	    $request.set_Timeout(15000) #15 second timeout

	    $response = $request.GetResponse()

	    $totalLengthKb = [System.Math]::Floor($response.get_ContentLength()/1024)
	    $totalLengthMb = [System.Math]::Floor($response.get_ContentLength()/1024/1024)
	    $totalLengthBytes = [System.Math]::Floor($response.get_ContentLength())
	    $responseStream = $response.GetResponseStream()
	    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $DestinationFilePath, Create
	    $buffer = new-object byte[] 10KB
	    $count = $responseStream.Read($buffer,0,$buffer.length)
	    $dlkb = 0
	    $downloadedBytes = $count
	    $script:steps = $totalLengthKb
	    while ($count -gt 0){
	       $targetStream.Write($buffer, 0, $count)
	       $count = $responseStream.Read($buffer,0,$buffer.length)
	       $downloadedBytes = $downloadedBytes + $count
	    }

	    $targetStream.Flush()
	    $targetStream.Close()
	    $targetStream.Dispose()
	    $responseStream.Dispose()
	    
	  }catch{
	    Write-Error $_
	    return $false
	  }
	}.GetNewClosure()
	[scriptblock]$ParallelDownloadSb = [scriptblock]::create($ParallelScript) 


	function Save-NirSoftLinksParallel{
	    [CmdletBinding(SupportsShouldProcess)]
	    param(
	        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="exp")]
	        [string]$Url,
	        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="DestinationPath")]
	        [string]$DestinationPath,
	        [Parameter(Mandatory=$false)]
	        [switch]$Test
	    )
	    $a = @("$Url","$DestinationPath")
	    $JobId = (Start-Job -ScriptBlock $ParallelDownloadSb -ArgumentList $a).Id 
	    [void]$Script:AllJobs.Add($JobId)
	}


	function Get-OnlineNirsoftFile{

	    [CmdletBinding(SupportsShouldProcess)]
	    param(
	        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="exp")]
	        [Alias("u")]
	        [string]$Url,
	        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="DestinationPath")]
	        [Alias("d")]
	        [string]$DestinationPath,
	        [Parameter(Mandatory=$false)]
	        [switch]$Parallel
	    )
	    try{
	      if($Parallel -eq $True){
	        Save-NirSoftLinksParallel -Url $link -DestinationPath $newpath
	      }else{
	        Save-NirsoftFile -Url $link -DestinationPath $newpath
	      }
	    }catch{
	      Write-Warning "Error Downloading `"$Url`""
	    }
	}

```


## Progress Bar

I have implemented a simple GUI Progress Message box, you can view the [code here](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/MsgBoxProgress)


-------------------

<br>


## Get the code 

[PowerShell.NirSoft on GitHub](https://github.com/arsscriptum/PowerShell.NirSoft)


***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL to guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**