---
layout: post
title:  "Test your Firewall using PowerShell"
summary: "Script to test your firewall from the outside,"
author: guillaume
date: '2023-07-04'
category: ['powershell','scripts', 'firewall', 'network', 'htmlagilitypack', 'html', 'parsing']
tags: powershell, scripts, resources, binary
thumbnail: /assets/img/posts/scanner/main.jpg
keywords: powershell, scripts, resources, binary
usemathjax: false
permalink: /blog/online-port-scanner/

---


### Overview 

Firewall Testing is the only way to accurately confirm whether the firewall is working as expected. Complicated firewall rules, poor management interfaces, and other factors often make it difficult to determine the status of a firewall. By using an external port scanner it is possible to accurately determine the firewall status. Personally, I needed a way to detect unauthorized changes in my config. Also, this is usefull when troubleshoting network access problems or detecting potential mishaps before they become a security castatrophe.

This type of firewall test attempts to make connections to external-facing services from the same perspective as an attacker. An unprotected open service (listening port) can be a major security weakness in poor firewall or router configurations.


### Why ? 

Here are some reasons you may want to use this script with an ***online port scanner***

1) Test Firewall Logging and IDS<br>
2) Find Open Ports<br>
3) Detect Unauthorized Firewall Changes<br>
4) Troubleshoot Network Services<br>

---------------------------------------------------------------------------------------------------------

### How ?


Pretty Straighforward. It uses an ***online port scanner*** , in this case [https://www.speedguide.net/portscan.php](https://www.speedguide.net/portscan.php) parses the replies using [HtmlAgilityPack](https://html-agility-pack.net/) . 

For your convienience, a function to install [HtmlAgilityPack](https://html-agility-pack.net/) is provided in [Install-HtmlAgilityPack.ps1](https://github.com/arsscriptum/PowerShell.Public.Sandbox/blob/master/OnlinePortScanner/Install-HtmlAgilityPack.ps1). You can also checkout my [Install-NugetPackage.ps1](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/InstallNugetPackage) script.  

### Possible States for Ports

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/scanner/table.jpg" alt="table" />
</center>
<br>

### Usage

Super easy, you provide port and the protocol. You can pass ```BOTH``` as protocol. In which case, you receive 2 results objects in the *Port* property.

```powershell
    # Checking port 80 on TCP
    Test-FirewallPort -Port 80 -Protocol TCP

    Start-Sleep 5  # Server limits request rate

    # Checking port 1194 on TCP and UDP
    Test-FirewallPort -Port 1194 -Protocol BOTH 

    # Port 64 on UDP
    Test-FirewallPort -Port 64 -Protocol UDP
```

### HtmlAgilityPack
To parse the results fro the online port scanner, we need to register [HtmlAgilityPack](https://html-agility-pack.net/)

```powershell

  function Register-HtmlAgilityPack{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$False)]
        [string]$Path
    )
    begin{
        if([string]::IsNullOrEmpty($Path)){
            $Path = "{0}\lib\{1}\HtmlAgilityPack.dll" -f "$PSScriptRoot", "$($PSVersionTable.PSEdition)"
        }
    }
    process{
      try{
        if(-not(Test-Path -Path "$Path" -PathType Leaf)){ throw "no such file `"$Path`"" }
        if (!("HtmlAgilityPack.HtmlDocument" -as [type])) {
            Write-Verbose "Registering HtmlAgilityPack... " 
            add-type -Path "$Path"
        }else{
            Write-Verbose "HtmlAgilityPack already registered " 
        }
      }catch{
        throw $_
      }
    }
  }

```

## Code : Test-FirewallPort

This ```Test-FirewallPort``` function will make a http request to ```https://www.speedguide.net``` and parse the results.

This webservice will detect you exxternal ip and will try to connect to the port you specified.


```powershell

  function Test-FirewallPort{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position = 0)]
        [int]$Port,
        [Parameter(Mandatory=$false)]
        [ValidateSet('TCP','UDP','BOTH')]
        [string]$Protocol="TCP",
        [Parameter(Mandatory=$false)]
        [switch]$DumpHtml
    )

   try{
        Add-Type -AssemblyName System.Web  

        $Null = Register-HtmlAgilityPack 
        $TestTCP = 0
        $TestUDP = 0
        $NumScans = 0
        if(($Protocol -eq 'TCP') -Or ($Protocol -eq 'BOTH')){ $TestTCP = 1 ; $NumScans++ }
        if(($Protocol -eq 'UDP') -Or ($Protocol -eq 'BOTH')){ $TestUDP = 1 ; $NumScans++ }

        $Url = "https://www.speedguide.net/portscan.php?tcp={0}&udp={1}&port={2}" -f $TestTCP, $TestUDP, $Port 
    

        $Results = Invoke-WebRequest -Uri $Url -Method Get
        Write-Verbose "Loading URL `"$Url`" "

        $StatusCode = $Results.StatusCode 
        if(200 -ne $StatusCode){
            Write-Error "Request Failed"
            return
        }

        $HtmlContent = $Results.Content 

        if($DumpHtml){
            $CurrentDir = (Get-Location).Path 
            $FilePath = Join-Path $CurrentDir "firewall-test-$Port.html"
            Set-Content -Path "$FilePath" -Value "$HtmlContent" -Force
            Write-Verbose "Dumping Html data in `"$FilePath`" "
        }
        [HtmlAgilityPack.HtmlDocument]$doc = @{}
        $doc.LoadHtml($HtmlContent)
        
        [string]$StrBuffer = ''
        [string[]]$PortScanResultsText = [string[]]::new($NumScans+1)
        Write-Verbose "NumScans $NumScans"
        [System.Collections.ArrayList]$ScanResultsList = [System.Collections.ArrayList]::new()
        For($i = 0 ; $i -lt $NumScans ; $i++){
            $TableIndex = 4 + $i
            Write-Verbose "========================= RESULT SET $i ================================="
            Write-Verbose "SelectNodes $TableIndex"
            $ResultSet = $doc.DocumentNode.SelectNodes("/html[1]/body[1]/table[1]/tr[1]/td[2]/table[1]/tr[$TableIndex]")
            $ResultSetInnerText = $ResultSet.InnerText
            Write-Verbose "====================== InnerText`n$($ResultSetInnerText)`n======================"
            if($ResultSetInnerText -notmatch "$Port") {  
                throw "Scan Results not found in server reply." 
            }

            [string[]]$PortScanResultsText = [System.Web.HttpUtility]::HtmlDecode($ResultSetInnerText).Split("`n")
        
            $x = 0
            while([string]::IsNullOrEmpty($PortScanResultsText[$x++])){}

            $Max = $PortScanResultsText.Count - 1
            $PortNumber = $PortScanResultsText[$x].Trim().Split('/')[0]
            $Protocol = $PortScanResultsText[$x++].Trim().Split('/')[1]
            $PortStatus = $PortScanResultsText[$x++].Trim()
            $PortService = $PortScanResultsText[$x++].Trim()
            $Description = $PortScanResultsText[$x .. $Max].Trim()

            $ScanResultObject = [PsCustomObject]@{
                Port = $PortNumber
                Protocol = $Protocol
                Status = $PortStatus
                Service = $PortService
                Description = $Description
            }
            [void]$ScanResultsList.Add($ScanResultObject) 
        }

        $ScanDetailsObject = [PsCustomObject]@{}
        
        For($i = 0 ; $i -lt 4 ; $i++){
            $TableIndex = 4 + $NumScans + $i
            $ResultSet = $doc.DocumentNode.SelectNodes("/html[1]/body[1]/table[1]/tr[1]/td[2]/table[1]/tr[$TableIndex]").InnerText
            $ScanDetails = $ResultSet.Split(':')
            [string]$StatName = $ScanDetails[0].Replace(' ','_').Trim() -as [string]
            [int32]$StatValue = $ScanDetails[1].Trim() -as [int32]
                
            $ScanDetailsObject | Add-Member -MemberType NoteProperty -Name "$StatName" -Value $StatValue -Force
        }

        $ScanDetailsObject | Add-Member -MemberType NoteProperty -Name "Ports" -Value $ScanResultsList -Force

        return $ScanDetailsObject
    }catch{
        Write-Error "$_"
    }
  }
```


### Returned Results Format

You get a PsCustomObject. Here's a JSON representation to give you an idea.

```powershell
    {
      "Total_scanned_ports": 1,
      "Open_ports": 0,
      "Closed_ports": 0,
      "Filtered_ports": 1,
      "Ports": [
        {
          "Port": "8088",
          "Protocol": "tcp",
          "Status": "filtered",
          "Service": "radan-http",
          "Description": "A port sometimes used for testing HTTP SERVERs"
        }
      ]
    }
```

<br>


### Get External Ip Information

For this we use ```http://ipinfo.io/json``` like this:

```powershell

  function Get-ExternalIpInformation{
    [CmdletBinding(SupportsShouldProcess)]
    param()
   try{
    $Data=(iwr 'http://ipinfo.io/json')
    if($Data.StatusCode -eq 200){
        Remove-Variable 'ExternalIpInformation' -ErrorAction ignore -Force
        $ExternalIpInformation = ($Data.Content | ConvertFrom-Json -AsHashtable)
        New-Variable -Name 'ExternalIpInformation' -Scope Global -Option ReadOnly,AllScope -Value $ExternalIpInformation -ErrorAction Ignore
        $ExternalIpInformation
    }
    }catch{
        Get-Variable -Name "ExternalIpInformation" -ValueOnly -Scope Global
    }
  }

```

### Important note

Upon getting an error in the request, you may have been rate-limited by the server. Try again later.


## Code: Request Port Description

This ```Request-PortDescription``` function will make a http request to ```https://www.grc.com/PortDataHelp.htm``` and parse the results.

This webservice will detect you exxternal ip and will try to connect to the port you specified.


```powershell
  function Request-PortDescription{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position = 0)]
        [int]$Port,
        [Parameter(Mandatory=$false)]
        [switch]$DumpHtml
    )
    Add-Type -AssemblyName System.Web  

    $HeadersData = @{
      "Accept-Encoding"="gzip, deflate, br"
      "Referer"="https://www.grc.com/PortDataHelp.htm"
    }

    $Uri = "https://www.grc.com/port?1={0}&2.x=39&2.y=9" -f $Port

    $Results = Invoke-WebRequest -Method Get -Uri $Uri -MaximumRedirection 2 -Headers $HeadersData -UseBasicParsing -ErrorAction Stop

    Write-Verbose "Loading URL `"$Url`" "

    $StatusCode = $Results.StatusCode 
    if(200 -ne $StatusCode){
        Write-Error "Request Failed"
        return
    }

    $HtmlContent = $Results.Content 

    if($DumpHtml){
        $CurrentDir = (Get-Location).Path 
        $FilePath = Join-Path $CurrentDir "grc_com-getportinfo-$Port.html"
        Set-Content -Path "$FilePath" -Value "$HtmlContent" -Force
        Write-Verbose "Dumping Html data in `"$FilePath`" "
    }
    [HtmlAgilityPack.HtmlDocument]$doc = @{}
    $doc.LoadHtml($HtmlContent)

    $PortInformation = $doc.DocumentNode.SelectNodes("/html[1]/body[1]/center[1]/form[1]/table[2]").InnerText
    $AdditionalInfos = $doc.DocumentNode.SelectNodes("/html[1]/body[1]/center[1]/form[1]/table[3]").InnerText

    $PortInformation = [System.Web.HttpUtility]::HtmlDecode($PortInformation)
    $AdditionalInfos = [System.Web.HttpUtility]::HtmlDecode($AdditionalInfos)

    $PortInfoObject = [PsCustomObject]@{}

    $PortInfoObject | Add-Member -MemberType NoteProperty -Name "PortInformation" -Value "$PortInformation" 
    $PortInfoObject | Add-Member -MemberType NoteProperty -Name "AdditionalInfos" -Value "$AdditionalInfos"
    $PortInfoObject
  }
```

### To test

```powershell
  Request-PortDescription 8080 -DumpHtml
```

### Important note

Upon getting an error in the request, you may have been rate-limited by the server. Try again later.

---------------------------------------------------------------------------------------------------------
<br>
<center>
<img src="https://arsscriptum.github.io/assets/img/posts/scanner/scanner.jpg" alt="scanner" />
</center>
---------------------------------------------------------------------------------------------------------
<br>
### Other Online Port Scanners

 - [nmap online](https://nmap.online/) : an online version of the nmap utility. You can query any website or IP address but only a small number of nmap features are available. You may need to create a free account. The port scan looks at TCP ports FTP(21), SSH(22), SMTP(25), HTTP(80), POP(110), IMAP(143), HTTPS(443) and SMB(445). The Fast scan option scans the most popular 100 ports.
 - [can you see me](https://canyouseeme.org/) : will only test your public IP address (your router). It tests one port at a time and will test any port. It says nothing about TCP vs. UDP, so probably only uses TCP.
 - [grc.com](https://www.grc.com/x/portprobe=1801)
 - [whatsmyip](https://www.whatsmyip.org/port-scanner/) : can scan a single port or four different groups of common ports. They don't say if the scans are TCP, UDP or both. A port that does not respond is said to time out. This does not differentiate between closed and stealthed ports, making it relatively useless.
 - [ipvoid](https://www.ipvoid.com/port-scan/) : scans any public IP address. If you opt for common ports, it scans: 21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 389, 443, 445, 587, 1025, 1080, 1433, 3306, 3389, 5900, 6001, 6379 and 8080.
 - [ipfingerprints](https://www.ipfingerprints.com/portscan.php) : ipfingerprints.com lets you test an arbitrary range of ports, both for TCP and UDP
 - [shodan](https://routersecurity.org/shodan.php)
 - [hackertarget nmap tool](https://hackertarget.com/nmap-online-port-scanner/)
 - [hackertarget fw test](https://hackertarget.com/firewall-test/)

---------------------------------------------------------------------------------------------------------
<br>

## Get the code 

[PowerShell.OnlinePortScanner on GitHub](https://github.com/arsscriptum/PowerShell.OnlinePortScanner/)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**