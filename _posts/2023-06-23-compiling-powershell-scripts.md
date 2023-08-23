---
layout: post
title:  "Compile and Obfuscate PowerShell Scripts"
summary: "Custom Method to compile and obfuscate a PowerShell Scripts to portable executable"
author: guillaume
date: '2023-06-22'
category: ['powershell','scripts', 'encryption', 'ps2exe', 'obfuscate']
tags: powershell, scripts, encryption
thumbnail: /assets/img/posts/pwsh_compilation/main.png
keywords: obfuscate, encryption, powershell, ps2exe
usemathjax: false
permalink: /blog/powershell-compilation-obfuscation/

---


### Converting PS1 to EXE

You can invoke PowerShell scripts in many different ways, but they all have one downfall, you can’t simply run them like a standard Windows program (EXE). Perhaps you’d like to prevent editing the code in a script or perhaps make it easier for your users to run scripts. It’s time to learn how to convert a PS1 to an EXE.

#### PS2EXE

PS2EXE is a free, open-source tool. Simple and straighforward, it can be used as a standalone script, a module, or a GUI application. Under the hood, it encapsulates the powershell script with in a host program coded in C# and compiles the dynamically generated C# source code in memory to an EXE file.

Visit the [github page](https://github.com/ikarstein/ps2exe) to review the tool.

##### Notes
 - The **host program** will run your script in a ***PowerShell v5*** environment. This cannot be changed due to missing .NET Core SDK capabilities
 - PS2EXE explicitly says that the compilation is not secure - anyone can extract the files with the correct switch. The only reason to use it is for convenience.
 - Some people **read: A LOT** have used it to compile malware, which is why AV solutions are picking it up. Due to this, most Anti-Virus software will block the executable from running


---------------------------------------------------------------------------------------------------------

<center>
<img src="/assets/img/posts/pwsh_compilation/banner1.png" alt="powershell compilation" />
</center>

### Now for the Serious Stuff

In order to get a useable portable executable compiled from a powershell script, we must drop the **PS2EXE** method, or actually adapt it to our needs.

Goal:
 - Simple way to compile a script
 - Support for all PowerShell functions in the executable
 - Get an executable that will not trigger the anti-virus detectors


#### Get Native.PowerShell.Wrapper

[Native.PowerShell.Wrapper on GitHub](https://github.com/arsscriptum/Native.PowerShell.Wrapper.git)


In this project I do the following:

1) Have a .NET Dll project that implements all the powershell functionalities required by the script. It integrates the **System.Automation.dll** as well.
2) The Dll contains the script in Base64 format.
3) I have an dummy  .NET console application that loads the Dll.
4) I use a custom obfuscator based on **ConfuserEx** to obfuscate the Dll/Exe and merge them in a single encoded Executable, completely unknown to the Anti-Virus software. 

#### How to use

1) Create your script.
2) Use ```scripts\Initialize-LibraryCode.ps1``` to generate the ```Wrapper.cs``` file in the Dll project.
3) Build using ```Build.bat```
4) The exe in in bin/protected.


---------------------------------------------------------------------------------------------------------



### How to obfuscate .NET assemblies with ConfuserEx

<img class="card-img-top-restricted-60"
     src="/assets/img/posts/pwsh_compilation/obfuctator.png"
     alt="Obfuctator" />

Software assemblies containing managed code, such as those used by .NET applications can be easily decompiled into readable source code using free decompilation tools.

This can present a challenge to application vendors who have a desire to prevent their code from being viewed or changed due to copyright or potential security concerns.

For any application that is deployed to a client device, complete protection from viewing or tampering with code cannot be guaranteed. However, by using an obfuscation tool, such as ConfuserEx, you can make it significantly harder to decompile your application.

ConfuserEx is an open-source obfuscation tool that can add several different protections to .NET assemblies. 

OLD, Unsupported Project Source: [https://github.com/mkaring/ConfuserEx](https://github.com/mkaring/ConfuserEx)

[Neo ConfuserEx](https://github.com/XenocodeRCE/neo-ConfuserEx) is the successor of ConfuserEx project, an open source C# obfuscator which uses its own fork of dnlib for assembly manipulation.

Project Source: [https://github.com/XenocodeRCE/neo-ConfuserEx](https://github.com/XenocodeRCE/neo-ConfuserEx)

[This custom Maelstrom.NET](https://github.com/arsscriptum/Maelstrom.NET) project implements the Neo ConfuserEx with some improvements. This is the one we use in our Native.PowerShell.Wrapper project.

### ConfuserEx Watermark

ConfuserEx contains some watermark that can be used by an anti-virus or other detector to know that ConfuserEx was used to obfuctate the assembly. I have removed those in [Maelstrom.NET](https://github.com/arsscriptum/Maelstrom.NET) project. But one must stay vigilant if serious about avoiding detection. 

You can do a basic detection of the watermark using [Strings](https://learn.microsoft.com/en-us/sysinternals/downloads/strings) with this command:

```
    (&"strings64.exe" "your exe") -match "Confuse"
```

<img class="card-img-top-restricted-60"
     src="/assets/img/posts/pwsh_compilation/watermark.png"
     alt="watermark" />


```
    1) Make sure that the file GlobalAssemblyInfo.Template.cs doesn't contain any reference to ConfuserEx, I personnaly set the reference properties to Google Chrome

    2) In Confuser.Core/ConfuserEngine.cs around 305. In function Inspection(). Disable the watermarking section.
```

---------------------------------------------------------------------------------------------------------

<center>
<img src="/assets/img/posts/pwsh_compilation/demo.gif" alt="demo" />
</center>

<center>
<img src="/assets/img/posts/pwsh_compilation/demo2.gif" alt="demo" />
</center>

<center>
<img src="/assets/img/posts/pwsh_compilation/stealth.gif" alt="demo" />
</center>


---------------------------------------------------------------------------------------------------------



## Get the code 

[Native.PowerShell.Wrapper on GitHub](https://github.com/arsscriptum/Native.PowerShell.Wrapper.git)