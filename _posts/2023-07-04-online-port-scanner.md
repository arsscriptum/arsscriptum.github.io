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
v
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

[OnlinePortScanner on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/OnlinePortScanner)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**