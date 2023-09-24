---
layout: post
title:  "PowerShell Best Practice: Returning BIG Objects from Functions"
summary: "Little hack to improve performance of functions returning big objects"
author: guillaume
date: '2023-09-23'
category: ['powershell','scripts', 'update', 'optimization', 'best practice']
tags: powershell, scripts, regex, regular, 'optimization', 'best practice'
thumbnail: /assets/img/posts/returnobj-optimization/main.png
keywords: powershell, scripts, optimization, best_practice
usemathjax: false
permalink: /blog/returnobj-optimization/

---

## Overview

Let's make a function that will return an array of bytes:

```powershell
  function Read-ByteArray([string]$Path) {
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$file_bytes = [byte[]]::new($fs.Length)
    $Null = $fs.Read($file_bytes, 0, $fs.Length) 
    $fs.Close()
    $fs.Dispose()
    $file_bytes
  }  
```

*Forget that there is a native .NET function to read bytes and follow me a bit...*

When you use that function to read a big file, like something in the order of hundreds of Megabytes, you will notice that the function takes a long time to execute. It should be right? I mean it's just reading bytes, not processing them...

## Returning BIG objects in PowerShell

When returning big arrays from function in PowerShell, ***you need to take into account that PowerShell unrolls your objects when you return them.***

The reason for the performance hang is not the *reading* of the bytes but *the way you return the data*.

a ```Return``` statement or just putting the variable on the last line like you did, you tell PowerShell to 'unrolls' the return object before returning. this can be long for big byte arrays. The solution is to just add the [unary comma](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.3&viewFallbackFrom=powershell-7#comma-operator-) ```,``` before the returned $byteArray like this:

```
  return ,$bytes
```

This will wrap the returned array inside another, one-element array. When an array is returned from a function, PowerShell 'unrolls' that and in this case, it unrolls the wrapper array, leaving the byte array inside.

Second option, you can use ```Write-Output -NoEnumerate``` Instead of return:


```
  Write-Output $bytes -NoEnumerate
```

To fix the function above we would have this:

```powershell
  function Read-ByteArray([string]$Path) {
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$file_bytes = [byte[]]::new($fs.Length)
    $Null = $fs.Read($file_bytes, 0, $fs.Length) 
    $fs.Close()
    $fs.Dispose()
    Write-Output $file_bytes -NoEnumerate
  }  
```


-------------------


Here's a test, with a file of 350MB

[Test Script](https://arsscriptum.github.io/assets/img/posts/returnobj-optimization/test.ps1)

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/returnobj-optimization/return.png" alt="table" />
</center>
<br>


