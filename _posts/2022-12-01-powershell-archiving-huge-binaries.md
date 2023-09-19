---
layout: post
title:  "Archiving Binaries on Github"
summary: "Using PowerShell to reformat huge binaries to circumvent Github pre-commit hooks"
author: guillaume
date: '2022-12-01'
category: ['powershell','scripts', 'archive']
tags: powershell, scripts, archive
thumbnail: /assets/img/posts/archiving-binaries-github/1.png
keywords: archive, powershell
usemathjax: false
permalink: /blog/powershell-archiving-binaries-github/

---


#### ORIGIN 

I wanted to archive a big ZIP file on Github. But as you can imagine, github prevents the usage of repositories to archive sizeable binaries like movies, audio files, zip files, etc...

#### Concept 

I created a script that changes a given binary file so that it is split in files on a maximum size and with the content being text, that is, converted to Base64. 

***Example***

A movie file named **Titanic.mp4 (400Mb)** will be converted to **400 text files** names *Titanic001.cpp ... Titanic400.cpp* which can then be commited in Github. 

---------------------------------------------------------------------------------------------------------


#### SPLITTING BINARY FILE 

```powershell

function SplitDataFile{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)] 
        [STRING] $Path,
        [Parameter(Mandatory = $false)] 
        [INT64] $Newsize = 1MB,
        [Parameter(Mandatory = $false)] 
        [STRING] $OutPath,
        [Parameter(Mandatory = $false)] 
        [switch] $AsString
    )

    if ($Newsize -le 0)
    {
        Write-Error "Only positive sizes allowed"
        return
    }

    $FileSize = (Get-Item $Path).Length
    $SyncStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $Script:ProgressTitle = "Split Files"
    $TotalTicks = 0
    $Count = [MAth]::Round($FileSize / $Newsize)
    $Script:StepNumber = 1
    $Script:TotalSteps = $Count + 3
    if($PSBoundParameters.ContainsKey('OutPath') -eq $False){
        $OutPath = [IO.Path]::GetDirectoryName($Path)

        Write-Verbose "Using OutPath from Path $Path"
    }else{
        Write-Verbose "Using OutPath $OutPath"
    }
    $OutPath = $OutPath.TrimEnd('\')

    if(-not (Test-Path -Path "$OutPath")){ 
        Write-Verbose "CREATING $OutPath"
        $Null= New-Item $OutPath -ItemType Directory -Force -ErrorAction Ignore
    }

    $FILENAME = [IO.Path]::GetFileNameWithoutExtension($Path)
    $EXTENSION  = [IO.Path]::GetExtension($Path)

    $MAXVALUE = 1GB # Hard maximum limit for Byte array for 64-Bit .Net 4 = [INT32]::MaxValue - 56, see here https://stackoverflow.com/questions/3944320/maximum-length-of-byte
    # but only around 1.5 GB in 32-Bit environment! So I chose 1 GB just to be safe
    $PASSES = [MATH]::Floor($Newsize / $MAXVALUE)
    $REMAINDER = $Newsize % $MAXVALUE
    if ($PASSES -gt 0) { $BUFSIZE = $MAXVALUE } else { $BUFSIZE = $REMAINDER }

    $OBJREADER = New-Object System.IO.BinaryReader([System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
    [Byte[]]$BUFFER = New-Object Byte[] $BUFSIZE
    $NUMFILE = 1

    do {
        $NEWNAME = "{0}\{1}{2,2:00}{3}" -f ($OutPath, $FILENAME, $NUMFILE, '.cpp')
        $Script:ProgressMessage = "Split {0} of {1} files" -f $Script:StepNumber, $Script:TotalSteps
        Invoke-AutoUpdateProgress_FileUtils
        $Script:StepNumber++
        $COUNT = 0
        $OBJWRITER = $NULL
        [INT32]$BYTESREAD = 0
        while (($COUNT -lt $PASSES) -and (($BYTESREAD = $OBJREADER.Read($BUFFER, 0, $BUFFER.Length)) -gt 0))
        {
            Write-Verbose " << READING $BYTESREAD bytes"
            if($AsString){
                $DataString = [convert]::ToBase64String($BUFFER, 0, $BYTESREAD)
                Write-Verbose "   >>> WRITING DataString to $NEWNAME"
                Set-Content $NEWNAME $DataString  
            }else{
                if (!$OBJWRITER)
                {
                    $OBJWRITER = New-Object System.IO.BinaryWriter([System.IO.File]::Create($NEWNAME))
                    Write-Verbose " + CREATING $NEWNAME"
                }
                Write-Verbose "   >>> WRITING $BYTESREAD bytes to $NEWNAME"
                $OBJWRITER.Write($BUFFER, 0, $BYTESREAD)  
            }
            $COUNT++
        }
        if (($REMAINDER -gt 0) -and (($BYTESREAD = $OBJREADER.Read($BUFFER, 0, $REMAINDER)) -gt 0))
        {
            Write-Verbose " << READING $BYTESREAD bytes"
            if($AsString){
                $DataString = [convert]::ToBase64String($BUFFER, 0, $BYTESREAD)
                Write-Verbose "   >>> WRITING DataString to $NEWNAME"
                Set-Content $NEWNAME $DataString  
            }else{
                if (!$OBJWRITER)
                {
                    $OBJWRITER = New-Object System.IO.BinaryWriter([System.IO.File]::Create($NEWNAME))
                    Write-Verbose " + CREATING $NEWNAME"
                }
                Write-Verbose "   >>> WRITING $BYTESREAD bytes to $NEWNAME"
                $OBJWRITER.Write($BUFFER, 0, $BYTESREAD)  
            }
        }

        if ($OBJWRITER) { $OBJWRITER.Close() }
        ++$NUMFILE
    } while ($BYTESREAD -gt 0)

    $OBJREADER.Close()
}

```

---------------------------------------------------------------


#### RE-COMBINING BINARY FILE from TEXT FILES 


```powershell

function CombineSplitFiles{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)] 
        [STRING] $Path,
        [Parameter(Mandatory = $true)] 
        [int] $TotalSize,
        [Parameter(Mandatory = $false)] 
        [STRING] $OutFilePath
    )
    $SyncStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $Script:ProgressTitle = "Combine Split Files"
    $TotalTicks = 0
    $Basename = ''
    Write-Verbose   "Path is $Path"
    $Files = (gci $Path -File).Name
    ForEach($f in $Files){
        if($f.Contains('01.cpp')){
            $Basename = $f.TrimEnd('01.cpp')
            
        }
    }
    Write-Verbose   "Basename is $Basename"
    $Files = (gci $Path -File).FullName
    $FilesCount = $Files.Count
    $Path = $Path.TrimEnd('\')
    $Position = 0 
    $Script:StepNumber = 1
    $Script:TotalSteps = $Files.Count
    [byte[]]$NewOutArray = [byte[]]::new($TotalSize)
    Write-Verbose " + CREATING $OutFilePath"
    For($x = 1 ; $x -le $FilesCount ; $x++){
        $DataFileName = "{0}\{1}{2,2:00}{3}" -f ($Path, $Basename, $x, '.cpp')
        Write-Verbose   "Working on $DataFileName"
        if(-not (Test-Path -Path "$DataFileName")){ 
            Write-Verbose   "ERROR NO SUCH FILE $DataFileName"
            continue;
        }
        $ReadBytes = get-content -LiteralPath $DataFileName
        $ReadBytesCount = $ReadBytes.Length
        Write-Verbose   "ReadBytesCount $ReadBytesCount"
        [byte[]] $outArray =[convert]::FromBase64String($ReadBytes);
        $outArraySize = $outArray.Length
        Write-Verbose "   >>> WRITING $outArraySize bytes (pos $Position)"
        $outArray.CopyTo($NewOutArray,$Position)
        $Position += $outArraySize
        [timespan]$ts =  $SyncStopWatch.Elapsed
        $TotalTicks += $ts.Ticks 
        $Script:ProgressMessage = "Combine {0} of {1} files" -f $Script:StepNumber, $Script:TotalSteps
        Invoke-AutoUpdateProgress_FileUtils
        $Script:StepNumber++
    }

   
    [io.file]::WriteAllBytes($OutFilePath,$NewOutArray)
    Write-Host "Wrote All Bytes to $OutFilePath"
}

```

---------------------------------------------------------------



---------------------------------------------------------------------------------------------------------


## Get the code 


[FileUtils on GitHub](https://github.com/arsscriptum/PowerShell.SplittingBinaries)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**