---
layout: post
title:  "PowerShell For Loops Performance"
summary: "Quick test on For Loops iteration performance"
author: guillaume
date: '2021-09-14'
category: ['powershell','scripts', 'system']
tags: powershell, scripts, system
thumbnail: /assets/img/posts/forloops-perf/1.png
keywords: system, powershell
usemathjax: false
permalink: /blog/forloops-perf/

---

### PowerShell FOR Iterators 

Small test to gauge the performance of the different types of ```For``` loops:

1. For
2. ForEach
3. ForEachObject

Test code:

```powershell
    $n = (1..1000) 
    function Test-for{
        $StopWatch = [system.diagnostics.stopwatch]::StartNew()
        For($i = 0 ; $i -lt 1000 ; $i++){
            $t = $i * 123456 - $i*123; $t = $t * $i * $i
        }
        $StopWatch.Stop()
        return $StopWatch.Elapsed.TotalMilliseconds
    }
    function Test-foreach{
        $StopWatch = [system.diagnostics.stopwatch]::StartNew()
        ForEach($i in $n){
            $t = $i * 123456 - $i*123; $t = $t * $i * $i
        }
        $StopWatch.Stop()
        return $StopWatch.Elapsed.TotalMilliseconds
    }
    function Test-foreachobject{
        $StopWatch = [system.diagnostics.stopwatch]::StartNew()
        $n | foreach-object {
            $t = $_ * 123456 - $_*123; $t = $t * $_ * $i
        }
        $StopWatch.Stop()
        return $StopWatch.Elapsed.TotalMilliseconds
    }
    Write-Host "==================" -f DarkRed
    Write-Host "   Test-foreach   " -f DarkYellow
    Write-Host "==================" -f DarkRed
    $v0=Test-for
    $v1=Test-foreach
    $v2=Test-foreachobject
    "Test-for          `t{0:n5}ms`nTest-foreach      `t{1:n5}ms`nTest-foreachobject`t{2:n5}ms`n------`nDiff fe/feo`t`t{3:n5}ms" -f $v0,$v1, $v2, ($v1-$v2)
```

Output this:


```bash
    ==================
       Test-foreach
    ==================
    Test-for                0.20910ms
    Test-foreach            0.16540ms
    Test-foreachobject      12.21550ms
    ------
    Diff fe/feo             -12.05010ms
```


---------------------------------------------------------------------------------------------------------
