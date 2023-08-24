---
layout: post
title:  "Bypass a Paywall"
summary: "Open a webpage that is behind a paywall with a simple but effective trick"
author: guillaume
date: '2022-04-04'
category: ['powershell','scripts', 'network']
tags: powershell, scripts, network
thumbnail: /assets/img/posts/invoke-bypass-paywall/1.png
keywords: network, powershell
usemathjax: false
permalink: /blog/invoke-bypass-paywall/

---

#### Invoke-BypassPaywall 

Open a webpage located behind a paywall.

```powershell
    function Invoke-BypassPaywall{

    <#
        .SYNOPSIS
        Invoke-BypassPaywall on a URL

        .DESCRIPTION
        Invoke-BypassPaywall opens a webpage locally after having downloaded the HTML code

        .PARAMETER URL
        The URL to open

        .EXAMPLE 

        >> This will to a generic search on the film Star Wars
           .\Invoke-BypassPaywall www.nytimes.com/article.html
    #>
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="url", Position=0)]
            [string]$Url
        )

        $fn = New-RandomFilename -Extension 'html'
      
        Write-Host -n -f DarkRed "[BypassPaywall] " ; Write-Host -f DarkYellow "Invoke-WebRequest -Uri `"$Url`""

        $Content = Invoke-WebRequest -Uri "$Url"
        $sc = $Content.StatusCode    
        if($sc -eq 200){
            $cnt = $Content.Content
            Write-Host -n -f DarkRed "[BypassPaywall] " ; Write-Host -f DarkGreen "StatusCode $sc OK"
            Set-Content -Path "$fn" -Value "$cnt"
            Write-Host -n -f DarkRed "[BypassPaywall] " ; Write-Host -f DarkGreen "start-process $fn"
            start-process "$fn"
        }else{
            Write-Host -n -f DarkRed "[BypassPaywall] " ; Write-Host -f DarkYellow "ERROR StatusCode $sc"
        }
    }
```