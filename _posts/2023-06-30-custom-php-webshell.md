---
layout: post
title:  "Control Panel: Custom PHP Web Shell"
summary: "A Small, Yet Elegant PHP WebShell with multiple functionalities"
author: guillaume
date: '2023-06-30'
category: ['powershell','scripts', 'win10', 'WebShell', 'powershell']
tags: powershell, scripts, xampp, win10
thumbnail: /assets/img/posts/webshell/main.jpg
keywords: powershell, scripts, xampp, win10
usemathjax: false
permalink: /blog/custom-php-webshell/

---

### Overview 

A powerful and delightful PHP WebShell

This is a lightweight PHP webshell, using only vanilla JavaScript and CSS, no jQuery/Bootstrap bloat.

A webshell is a shell that you can access through the web. This is useful for when you have firewalls that filter outgoing traffic on ports other than port 80. As long as you have a webserver, and want it to function, you can't filter our traffic on port 80 (and 443). It is also a bit more stealthy than a reverse shell on other ports since the traffic is hidden in the http traffic.

This WebShell lets the user run powershell scripts, upload files, download files, browse in the directories, run executables, etc...

### Rome-Shell

This Web Shell was based from the [rome-webshell](https://github.com/Caesarovich/rome-webshell) code. I fixed bugs occuring on Windows 10 and added some functionalities I needed.

### Functionalities

1) run powershell scripts<br>
2) upload files<br>
3) download files<br>
4) browse in the directories<br>
5) run executables<br>

### Panel

Here's some details on the Main Panel Interface

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/webshell/panel-00.png" alt="info" style="max-width: 85%;" />
</center>
<br>

Here's a screen shot of a script executing...


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/webshell/panel-01.png" alt="info" style="max-width: 85%;" />
</center>
<br>

### Obfuscation of the Code

See [the PhpObfuscate repo](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/PhpObfuscate)


```powershell
    cd .\scripts\
    . .\run_obfuscate.ps1

    [OBFUSCATION] Operation Completed. "... obfuscated\coded.php"
```
 
<br>

---------------------------------------------------------------------------------------------------------


## Get the code 

[Php.WebShell.CtrlPanel on GitHub](https://github.com/arsscriptum/Php.WebShell.CtrlPanel)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**