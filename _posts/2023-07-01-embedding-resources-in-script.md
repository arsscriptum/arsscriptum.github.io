---
layout: post
title:  "Embed Resources and Dependencies in PowerShell Scripts"
summary: "Methods with which you can embed and extract all dependencies in you script."
author: guillaume
date: '2023-07-01'
category: ['powershell','scripts', 'resources', 'binary', 'powershell']
tags: powershell, scripts, resources, binary
thumbnail: /assets/img/posts/embedding_dependencies/main.jpg
keywords: powershell, scripts, resources, binary
usemathjax: false
permalink: /blog/embedding-resources-in-script/

---

### Overview 

When I compile a PowerShell script to a portable executable, the latter requires all the dependencies that are required by the PS1 script. In fact, a compiled PowerShell script is executing in the same exact PowerShell environment as it is when I run the PS1. So if your script loads, for example, a ```png image``` from ```c:\Images\background.png``` , the portable executable will do the same.

Having dependencies for a script is bad practice, but dependencies on a compiled version ? A portable executable version ? It defeats the purpose of compiling the script in the first place... Right!?!

Here's some notes on how to embed binaries like images, libraries, etc in a PowerShell script so that we solve this dependencies issue. This is valid for both a script or compiled version of the PowerShell code.

---------------------------------------------------------------------------------------------------------

### Embedding Images

Including binary images in a script is like emedding any other binary files, but some care must be applied when converting the data to the image container.

The code block below shows how to convert and represent a resource as a base 64 string. The last 2 lines are adding a string variable in the script.

```powershell

 # Get-Content Support for PS5 and PSCore
function Get-ContentBytes{ 
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Mandatory=$true)]
        [string]$Path
    )
    if($PSVersionTable.PSEdition -eq 'Core'){
        return ((Get-Content -Path "$Path" -AsByteStream) -As [byte[]])
    }else{
        return ((Get-Content -Path "$Path" -Encoding Byte) -As [byte[]])
    }

}

$ImageScriptName = "$PSScriptRoot\scripts\Images.ps1"
Set-Content -Path "$ImageScriptName" -Value "# images definitions`n`n"
$i = 0
$AllImages = (Get-ChildItem (Get-ImgPath) -File).Fullname
ForEach($img in $AllImages){
   # create a byte array from our image file
    Write-Host "Creating ByteArray from $img" -f Blue
    [byte[]]$DataBuffer = Get-ContentBytes -Path "$img" 

    # from the byet aray, create a base 64 string representing our file...
    $Base64JsonData = [System.Convert]::ToBase64String($DataBuffer)

    # create a code block to add to our script
    $StrToAdd = "`$Image_{0:d3} = `"{1}`" " -f $i++, $Base64JsonData

    # adding a string variable in the script
    Add-Content -Path "$ImageScriptName" -Value "$StrToAdd"
}
```

This will generate a file like this:

```powershell
   $Image_000 = "/9j/4AAQSkZJRgABAQEAYABgAAD/4QAiRXh .... "
```

<br><br>

Straighforward enough... Now let's ***uno reverse*** extract an embedded image resource and use it in our script.

1) Convert the ***Base64 string to Bitmap***

```powershell
  # Takes a Base64 string representing an encoded image and convert it to a BitmapImage
  # Special attention must be employed when selecting the ImageType, It must be the same as the base64-encoded image type.

  function ConvertTo-BitmapImage {
    [CmdletBinding(SupportsShouldProcess)]
      param(
          [Parameter(Position = 0, Mandatory = $true)]
          [string]$Base64String,
          [Parameter(Position = 1, Mandatory = $True)]
          [ValidateSet("Bmp", "Emf", "Exif", "Gif", "Icon", "Jpeg", "MemoryBmp", "Png", "Tiff", "Wmf")]
          [string]$ImageType
      )

    [System.Drawing.Imaging.ImageFormat]$Format = [System.Drawing.Imaging.ImageFormat]::$ImageType

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
    [System.Drawing.Bitmap]$bmp = [System.Drawing.Bitmap]::FromStream((New-Object System.IO.MemoryStream (@(, [Convert]::FromBase64String($Base64String)))))
    $memory = New-Object System.IO.MemoryStream
    $null = $bmp.Save($memory, $Format)
    $memory.Position = 0
    $img = New-Object System.Windows.Media.Imaging.BitmapImage
    $img.BeginInit()
    $img.StreamSource = $memory
    $img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $img.EndInit()
    $img.Freeze()

    $memory.Close()

    $img
  }
```

2) In WPF, an Image instance has the type ```[System.Windows.Media.ImageSource]``` .
3) To use our embedded resource, just assign the [BitmapImage] to the **Source** property : 


```powershell
    # the resource is now loaded...
    [System.Windows.Media.Imaging.BitmapImage]$BitmapObj = ConvertTo-BitmapImage $ImageBase64Data -ImageType Jpeg
    $BgImageVar.Source = $BitmapObj
```


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/embedding_dependencies/demo.gif" alt="table" />
</center>
<br>



-------------------


### Embed an Assembly in a PowerShell Script

You can embed a .NET assembly directly in a PowerShell script and load it with the Assembly class.

First, convert the assembly to base64. This example uses NewtonSoft.Json.

```powershell
    $Bytes = [IO.File]::ReadAllBytes("NewtonSoft.Json.dll")
    $Base64 = [Convert]::ToBase64String($Bytes)
```

Next, in your PS1, you can include the base64 string directly in the code. Then, convert it back to bytes and load it with the assembly class.

```powershell
    $Base64 = "base64-string"
    $Bytes = [Convert]::FromBase64String($Base64)
    # Load the Dll from memory using simply this call
    [System.Reflection.Assembly]::Load($Bytes)         ### << important!
```



-------------------



### Loading Embedded Dll from Resources

The following C# code can be added as a custom type in PowerShell, then used to load Dll assemblies from a **byte array**

```powershell
    public MainWindow()
    {
        InitializeComponent();

        AppDomain.CurrentDomain.AssemblyResolve += (sender, args) =>
        {
            Assembly thisAssembly = Assembly.GetEntryAssembly();
            String resourceName = string.Format("{0}.{1}.dll",
                thisAssembly.EntryPoint.DeclaringType.Namespace,
                new AssemblyName(args.Name).Name);

            using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName))
            {

                Byte[] assemblyData = new Byte[stream.Length];

                stream.Read(assemblyData, 0, assemblyData.Length);

                return Assembly.Load(assemblyData);

            }

        };
    }
```

## Converters - ConvertFrom-HeaderBlock / ConvertTo-HeaderBlock

These 2 functions are used to include a file (scripts, binary, etc) as a resource in another text file. The latter is represented as a text header like this:

```powershell
  <# === BEGIN EMBEDDED FILE HEADER === 
  H 4 s I A A A A A A A A C p 1 W X U / b M B R 9 r 9 T / c F V V a q K R a H t
  F q g S U d m J j r K I V L 6 x C J r l t g l y 7 2 A 5 d B f z 3 X T s f N Q
  y I h 0 C D 6 j M V E Y W q Q S t R a m x a T t / A F v B l 2 7 4 C A A A
  === END EMBEDDED FILE HEADER === #>
```

### How does it work ?

#### Include a resource in a file

The function ```ConvertTo-HeaderBlock``` takes a file path, then:

1. get all  the bytes from the file
2. detect if the file is binary or text
3. create a header including the file format and byte array size
4. compress the byte array, including header using GZIP
5. convert the data to Base 64 for text representation
6. split the data in similar subgroups to have a pretty header block

All you need to do afterwards is to include that block of text whereever you want in the file of your choice.

***NOTE THAT WHEN YOU EXTRACT THE DATA FROM THE FILE IT WAS INCLUDED IN, THE LOCATION OF THE TEXT BLOCK IS NOT IMPORTANT, CAN BE AT THE BEGINNING, MID or END OF FILE...***

#### Retrieve a resoure from a file


The function ```ConvertFrom-HeaderBlock``` takes a file path, then:

1. locate the text block that contains the resource in the file specified.
2. convert Base64 to byte array
3. decompress the bytes using GZIP
4. read the header including the file format and byte array size
5. get the raw byte array
6. convert to text if required


### Test - Converter

```powershell
    . .\test\Test-ConvertScriptToHeader.ps1 -Verbose
```

### Test - Embedded Resources - Images

Here's a fun test, this function will generate a header block based on a JPG image file and include that text in the script.
The script will parse this text and extract the image the it uses in it's code.


```powershell
     . .\test\Test-RunImageLauncher.ps1
```

### DEMO 1

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/embedding_dependencies/demo_1.gif" alt="table" />
</center>
<br>



### DEMO 2

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/embedding_dependencies/demo_img.gif" alt="table" />
</center>
<br>


### DEMO 3

<center>
<img src="https://arsscriptum.github.io/assets/img/posts/embedding_dependencies/demo_2.gif" alt="table" />
</center>
<br>


## Script Encoder - Simple Packager

Takes 2 file and file bundle them together into one binary, compressed, data file. I contains the file data and their names and path. You can
deserialized them in a separate folder or deserialize them o overwrite the original if you want.

### How to use

```powershell
  $MyScript = "c:\script.ps1"
  $DataFile = "c:\results.json"

  # create an encoded file with the script and the results file
  $SavedDataFile = New-EncodedFile -ScriptPath $MyScript -DataFilePath $DataFile
```

To get the files back from the encoded file

```powershell
  $null = mkdir "$pwd\out" -Force -ea Ignore
  # extract in directory I specified
  Restore-EncodedFiles -Path $SavedDataFile -DestinationPath "$pwd\out"
  # extract and overwrite originals.
  Restore-EncodedFiles -Path $SavedDataFile -OverwriteOriginalFiles
```


-------------------


## Get the code 

[EmbeddedImageInScript on GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/EmbeddedImageInScript)

[PowerShell.EncodeFile on GitHub](https://github.com/arsscriptum/PowerShell.EncodeFile)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**