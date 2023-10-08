---
layout: post
title:  "Bypass Website Paywall"
summary: "Small PowerShell Script to Bypass a Website Paywall"
author: guillaume
date: '2023-10-07'
category: ['powershell','scripts', 'network']
tags: powershell, scripts, network
thumbnail: /assets/img/posts/bypass-paywall/main.png
keywords: network, powershell
usemathjax: false
permalink: /blog/bypass-paywall/

---

## Read articles without annoying paywalls

We’ve all been there: we’re scrolling and come across a news article that grabs our attention. Curiously, we click the link only to be blocked by a paywall.
Suddenly you’re faced with the decision: subscribe, perform a Google search for a free version, or abandon reading it altogether. But there’s another option: bypassing those paywalls to read the content for free.

## Simple powershell script

This script just does the following:

1. Get the page in question
1. Save the content locally
1. Open the local page using your browser

This relies on the fact that Paywall are using cookies to check if you are subscribed, when you save the page locally, the checks normally done when you are onine are not done, so you can view the page. Simple, but it works.

Note that some pages will not display properly, you can see/read the text but some image ae not placed corectly like in the ```https://washingtonpost.com```

```powershell

  > Invoke-BypassPaywall "https://washingtonpost.com/world/2023/10/07/israel-gaza-hamas-attack-palestinians/


```


### CODE


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

    # New Random Filename
    [string]$epoch_str = (get-date -UFormat %s) -as [string]
    [string]$fn        = "{0}\bypasspaywall_{1}.html" -f "$ENV:TEMP", $epoch_str

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



-------------------