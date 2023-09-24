---
layout: post
title:  "PowerShell Script autoUpdate"
summary: "Having a script check for it's latest version and auto update and relauch if available"
author: guillaume
date: '2023-09-22'
category: ['powershell','scripts', 'update', 'optimization', 'best practice']
tags: powershell, scripts, regex, regular, 'optimization', 'best practice'
thumbnail: /assets/img/posts/returnobj-optimization/main.png
keywords: powershell, scripts, optimization, best_practice
usemathjax: false
permalink: /blog/returnobj-optimization/

---


## Returning BIG objects in PowerShell

When returning big arrays from function in PowerShell, you need to take into account that PowerShell unrolls your objects when you return them.

You will notice that if you use your function ```Read-ByteArray``` to read a big file (like a few hundreds MB), it will take a long time. The reason is not the reading of the bytes but the way you return the data.

a ```Return``` statement or just putting the variable on the last line like you did, you tell PowerShell to 'unrolls' the return object before returning. this can be long for big byte arrays. The solution is to just add the [unary comma](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.3&viewFallbackFrom=powershell-7#comma-operator-) ```,``` before the returned $byteArray like this:

```
  return ,$bytes
```

This will wrap the returned array inside another, one-element array. When an array is returned from a function, PowerShell 'unrolls' that and in this case, it unrolls the wrapper array, leaving the byte array inside.

Second option, you can use ```Write-Output -NoEnumerate``` Instead of return:


```
  Write-Output $bytes -NoEnumerate
```

Here's a test, with a file of 350MB


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/returnobj-optimization/return.png" alt="table" />
</center>
<br>



```powershell

  <#
   Read a Byte Array, return the data with Write-Output -NoEnumerate (not unrolling)
  #>
  function Read-ByteArray_NoEnum([string]$Path) {
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$file_bytes = [byte[]]::new($fs.Length)
    $Null = $fs.Read($file_bytes, 0, $fs.Length) 
    $fs.Close()
    $fs.Dispose()

    # Using Write-Output
    Write-Output $file_bytes -NoEnumerate
  }  
  
  $time_spent = Measure-Command { $b = Read-ByteArray_NoEnum("$f") }
  $log_results =  "Read-ByteArray_NoEnum {0:N2} seconds" -f $time_spent.TotalSeconds
  Write-Host "$log_results`n" -f DarkYellow

  <#
    Read a Byte Array, return the data in another object using the unary comma
  #>
  function Read-ByteArray_Unary([string]$Path) {
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$file_bytes = [byte[]]::new($fs.Length)
    $Null = $fs.Read($file_bytes, 0, $fs.Length) 
    $fs.Close()
    $fs.Dispose()
    
    # return using unary comma
    ,$file_bytes
  } 

  $time_spent = Measure-Command { $b = Read-ByteArray_Unary("$f") }
  $log_results =  "Read-ByteArray_Unary {0:N2} seconds" -f $time_spent.TotalSeconds
  Write-Host "$log_results`n" -f DarkYellow

  <#
   Read a Byte Array, return the data normally (powershell will unroll the object)
  #>
  function Read-ByteArray_Ret([string]$Path) {
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$file_bytes = [byte[]]::new($fs.Length)
    $Null = $fs.Read($file_bytes, 0, $fs.Length) 
    $fs.Close()
    $fs.Dispose()
    
    # simple return
    $file_bytes
  }  

  $time_spent = Measure-Command { $b = Read-ByteArray_Ret("$f") }
  $log_results =  "Read-ByteArray_Ret {0:N2} seconds" -f $time_spent.TotalSeconds
  Write-Host "$log_results`n" -f DarkYellow

```


-------------------


<br>


## Get the code 

[AutoUpdateScript on GitHub](https://github.com/arsscriptum/PowerShell.Reddit.Support/tree/master/ReturnOptimization)


***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL to guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**