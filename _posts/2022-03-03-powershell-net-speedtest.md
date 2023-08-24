---
layout: post
title:  "Speed Test in PowerShell"
summary: "Testing network speed using ookla application"
author: guillaume
date: '2022-03-03'
category: ['powershell','scripts', 'network']
tags: powershell, scripts, network
thumbnail: /assets/img/posts/posh-speedtest/1.png
keywords: network, powershell
usemathjax: false
permalink: /blog/posh-speedtest/

---

#### Install-SpeedTest and Invoke-ConnectionTest 

The 2 functions required to rapidly test network speed.

```powershell
        [CmdletBinding(SupportsShouldProcess=$true)]
        param()

    function Save-NetworkFile{
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory=$true)]
            [Alias('u')]
            [string]$Url,
            [Parameter(Mandatory=$false)]
            [Alias('Destination', 'p')]
            [string]$Path
        )

        if( -not ($PSBoundParameters.ContainsKey('Path') )){
            $Path = (Get-Location).Path
            [Uri]$Val = $Url;
            $Name = $Val.Segments[$Val.Segments.Length-1]
            $Path = Join-Path $Path $Name
        }
        $ForceNoCache=$True

        $client = New-Object Net.WebClient
       
        $client.Headers.Add("user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Mobile/15E148 Safari/604.1") 
        
        $RequestUrl = "$Url"

        if ($ForceNoCache) {
            # doesn’t use the cache at all
            $client.CachePolicy = New-Object Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::NoCacheNoStore)

            $RandId=(new-guid).Guid
            $RandId=$RandId -replace "-"
            $RequestUrl = "$Url" + "?id=$RandId"
        }
        Write-Verbose "Requesting $RequestUrl"
        Write-Verbose "Path $Path"
        $client.DownloadFile($RequestUrl,$Path)
    }

    function Invoke-ConnectionTest{

        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(Mandatory = $false)]
            [string]$Url = 'https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip'
        )
        try{

            $download_path = Join-Path "$env:TEMP" -ChildPath "teewttest\download"
            $program_path = "c:\Temp"
            $SpeedTestExe = Join-Path $program_path 'speedtest.exe'
            $SpeedTestCsv = Join-Path $program_path 'speedtest.csv'
            $stdout = Join-Path $program_path 'stdout.log'
        
        
            if (-not (Test-Path $download_path -PathType Container)) {
                Write-Verbose "mkdir $download_path"
                $null = New-Item -Path $download_path -ItemType Directory
            }
            
            Write-Verbose "Downloading SpeedTest commandline tool prior to extraction."
            [Uri]$DlUri = $Url
            $fname = $DlUri.Segments[$DlUri.Segments.Count-1]
            
            $downloaded_filepath = "$download_path\$fname"
            Write-Verbose "Save-NetworkFile -Url `"$Url`" -Path `"$downloaded_filepath`""
            Save-NetworkFile -Url $Url -Path $downloaded_filepath
            if(-not(Test-Path $downloaded_filepath)){
                throw "Download error"
            }

            $Len = (gi "$downloaded_filepath").Length
            
            if($Len -gt 0){
                Write-Verbose "Len $Len"
                $Len = (gi "$downloaded_filepath").Length 
                Start-Sleep -Milliseconds 500
                [System.IO.FileSystemInfo[]]$decompressed_files = Expand-Archive -Path "$downloaded_filepath" -DestinationPath "$program_path" -Force -PassThru -ErrorAction Ignore
                $SpeedTestExe = $decompressed_files[0].Fullname

            }
            [RegEx]$regpattern = '^(?<Date>[\[\]\\\-\:\.\ 0-9]+)(\s+)(?<Type>[\[\]\w+]*)'
            $CsvData = &"$SpeedTestExe" '--progress=no' '--format=csv' '--output-header' '--accept-license' '2>' "$stdout"
            $stdout_data = Get-Content $stdout
             # $stdout_data
            if($stdout_data -Match $regpattern){
                $type = $Matches.Type
                $stdout_first = $stdout_data[0]
                if($type -eq '[error]'){ throw "speedtest.exe error $stdout_first"}
            }
            Set-Content -Path $SpeedTestCsv -Value $CsvData
            $Results = Import-Csv $SpeedTestCsv
            return $Results
        }catch{
            Write-Error $_
        }
    }   

    Invoke-ConnectionTest 

```

Output

```bash
    server name             : Bell Canada - Boucherville, QC
    server id               : 52028
    idle latency            : 27.6871
    idle jitter             : 14.5845
    packet loss             : 0
    download                : 2112378
    upload                  : 1406001
    download bytes          : 15425334
    upload bytes            : 5623751
    share url               : https://www.speedtest.net/result/c/db3244ee-10f3-43ed-b0e4-0324782ca623
    download server count   : 1
    download latency        : 92.1686
    download latency jitter : 26.9635
    download latency low    : 16.975
    download latency high   : 397.696
    upload latency          : 21.1534
    upload latency jitter   : 8.38683
    upload latency low      : 9.808
    upload latency high     : 105.138
    idle latency low        : 15.361
    idle latency high       : 36.484
```