---
layout: post
title:  "Obfuscate PHP code with PowerShell"
summary: "How to programatically Obfuscate PHP code with PowerShell using the website [https://www.gaijin.at/en/tools/php-obfuscator](https://www.gaijin.at/en/tools/php-obfuscator)"
author: guillaume
date: '2023-06-29'
category: ['powershell','scripts', 'php', 'obfuscation', 'powershell']
tags: powershell, scripts, obfuscation, php
thumbnail: /assets/img/posts/php_obfuscation/main.png
keywords: powershell, scripts, obfuscation, php
usemathjax: false
permalink: /blog/php-scripts-obfuscation/

---
# Obfuscate PHP code with PowerShell

Here's a small PowerShell script that I use to obfucate PHP code. It uses the [https://www.gaijin.at/en/tools/php-obfuscator](https://www.gaijin.at/en/tools/php-obfuscator) website.

### Use Case
```
    cd scripts
    . .\run_obfuscate.ps1
```


### Important Note regarding Function Rename

The function rename functionality is implemented locally and doesn't rely on the online obfuscation system. Although there is such a functionality and it works fine, the problem I have with it is that most ```php``` code contains not only php, but also html. And the html often contains references to php functions.

Since we send only the block of php code to the online obfuscation system, our html code is not updated with the new function names and there's no easy way to fix that after the fact.

So I have implemented the functionality locally and the functions are renamed in both the php and html code blocks. Then we send the php code for additional obfuscation using the other methods available to us:

- RemoveComments 
- ObfuscateVariables 
- EncodeStrings 
- UseHexValuesForNames 
- RemoveWhitespaces


To demonstrate with clarity what those functionalities are actually doing to your code, I have divided them in 4 levels of complexity:

<br>
### Obfuscation Level 1 - Obfuscate Variables


```
  Invoke-PhpObfuscator $Src $Dst -RemoveComments -ObfuscateVariables 
```

<br>
### Obfuscation Level 2 - Obfuscate Variables + Encode Strings

```
  Invoke-PhpObfuscator $Src $Dst -RemoveComments -ObfuscateVariables -EncodeStrings 
```

<br>
### Obfuscation Level 3 - Level 2 + Use Hex Values For Names + Remove Whitespaces

```
  Invoke-PhpObfuscator $Src $Dst -RemoveComments -ObfuscateVariables -EncodeStrings -UseHexValuesForNames -RemoveWhitespaces
```

<br>
### Obfuscation Level 4 - Level 3 + Rename all Functions

```
  Invoke-PhpObfuscator $Src $Dst -RemoveComments -ObfuscateVariables -EncodeStrings -UseHexValuesForNames -RemoveWhitespaces -RenameFunctions -RenamingMethod "MD5" -Md5Length 24 -PrefixLength 8
```


---------------------------------------------------------------------------------------------------------

<br>

### Demo Full Obfuscation [full screen](https://github.com/arsscriptum/PowerShell.Public.Sandbox/blob/master/PhpObfuscate/gif/demo_full.gif)

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/php_obfuscation/demo_full.gif" alt="info" style="max-width: 70%;" />
</center>

---------------------------------------------------------------------------------------------------------

<br>

![Full Obfuscation Demo]()


### Demo the 4 different Obfuscation levels [full screen](https://github.com/arsscriptum/PowerShell.Public.Sandbox/blob/master/PhpObfuscate/gif/demo_4levels.gif)


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/php_obfuscation/demo_4levels.gif" alt="info" style="max-width: 70%;" />
</center>

---------------------------------------------------------------------------------------------------------

<br>

## Get the code 

[PhpObfuscate on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/PhpObfuscate)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**