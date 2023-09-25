---
layout: post
title:  "CRC Check in PowerShell"
summary: "Various Cyclic Redundancy Check implementation in PowerShell"
author: guillaume
date: '2023-09-19'
category: ['powershell','scripts', 'update', 'check', 'crc']
tags: powershell, scripts, regex, regular, 'check', 'crc'
thumbnail: /assets/img/posts/powershell-crc/main.png
keywords: powershell, scripts, crc, test
usemathjax: false
permalink: /blog/powershell-crc/

---


# CRC CALCULATOR - C# / POWERSHELL

CRC stands for Cyclic Redundancy Check. It is an error-detecting code used to determine if a block of data has been corrupted. CRC is a great technique for detecting common transmission errors. 
The receiving device also calculates the CRC and compares it to the CRC from the sending device. If even one bit in the message is received incorrectly, the CRCs will be different and an error will result.

I initially made this because the ```Get-Filehash``` was slow for big files, and some CRC implementation below are faster, some are slower.

-------------------

## Pure CRC PowerShell Implementation

```powershell

  function Get-CRC32 {
      <#
          .SYNOPSIS
              Calculate CRC.
          .DESCRIPTION
              This function calculates the CRC of the input data using the CRC32 algorithm.

              For a Test File, this CRC for a file length 349.83 MB (366819792 bytes): 157.39 seconds
          .EXAMPLE
              Get-CRC32 $data
          .EXAMPLE
              $data | Get-CRC32
          .INPUTS
              byte[]
          .OUTPUTS
              uint32
      #>
      [CmdletBinding(SupportsShouldProcess)]
      param (
          # Array of Bytes to use for CRC calculation
          [Parameter(Mandatory=$true, Position = 0)]
          [ValidateNotNullOrEmpty()]
          [byte[]]$Bytes
      )

      Begin {

          function New-CrcTable {
              [uint32]$c = $null
              $crcTable = New-Object 'System.Uint32[]' 256

              for ($n = 0; $n -lt 256; $n++) {
                  $c = [uint32]$n
                  for ($k = 0; $k -lt 8; $k++) {
                      if ($c -band 1) {
                          $c = (0xEDB88320 -bxor ($c -shr 1))
                      }
                      else {
                          $c = ($c -shr 1)
                      }
                  }
                  $crcTable[$n] = $c
              }

              Write-Output $crcTable
          }

          function Update-Crc ([uint32]$crc, [byte[]]$buffer, [int]$length) {
              [uint32]$c = $crc

              if (-not($script:crcTable)) {
                  Write-Verbose "[Update-Crc] New-CrcTable start"
                  $script:crcTable = New-CrcTable
                  Write-Verbose "[Update-Crc] New-CrcTable done"
              }


              Write-Verbose "[Update-Crc] start ($length bytes)"
              for ($n = 0; $n -lt $length; $n++) {
                  $c = ($script:crcTable[($c -bxor $buffer[$n]) -band 0xFF]) -bxor ($c -shr 8)
              }
              Write-Verbose "[Update-Crc] done"
              Write-output $c 
          }

          
      }
      process{
        try{
          Write-Verbose "[Get-CRC32] clone data"
          [byte[]]$dataArray = $Bytes.Clone()
          [uint32]$inputLength = $dataArray.Length
          Write-Verbose "[Get-CRC32] Update-Crc (len $inputLength bytes)"
          [uint32]$tmp_crc_buf = Update-Crc –crc 0xffffffffL –buffer $dataArray –length $inputLength
          [uint32]$crc_value = ($tmp_crc_buf -bxor 0xffffffffL)
          Write-output $crc_value 
        }catch{
          Write-Error "$_"
        } 
      }
  }

```

-------------------


## C# Implementation

Here's a C# Implementation integrated in the PowerShell script


```csharp

  using System;
  public static class ModRTU_CRC
  {
      public static readonly ushort[] CRCTable =
      {
          0X0000, 0XC0C1, 0XC181, 0X0140, 0XC301, 0X03C0, 0X0280, 0XC241, 0XC601, 0X06C0,
          0X0780, 0XC741, 0X0500, 0XC5C1, 0XC481, 0X0440, 0XCC01, 0X0CC0, 0X0D80, 0XCD41,
          0X0F00, 0XCFC1, 0XCE81, 0X0E40, 0X0A00, 0XCAC1, 0XCB81, 0X0B40, 0XC901, 0X09C0,
          0X0880, 0XC841, 0XD801, 0X18C0, 0X1980, 0XD941, 0X1B00, 0XDBC1, 0XDA81, 0X1A40,
          0X1E00, 0XDEC1, 0XDF81, 0X1F40, 0XDD01, 0X1DC0, 0X1C80, 0XDC41, 0X1400, 0XD4C1,
          0XD581, 0X1540, 0XD701, 0X17C0, 0X1680, 0XD641, 0XD201, 0X12C0, 0X1380, 0XD341,
          0X1100, 0XD1C1, 0XD081, 0X1040, 0XF001, 0X30C0, 0X3180, 0XF141, 0X3300, 0XF3C1,
          0XF281, 0X3240, 0X3600, 0XF6C1, 0XF781, 0X3740, 0XF501, 0X35C0, 0X3480, 0XF441,
          0X3C00, 0XFCC1, 0XFD81, 0X3D40, 0XFF01, 0X3FC0, 0X3E80, 0XFE41, 0XFA01, 0X3AC0,
          0X3B80, 0XFB41, 0X3900, 0XF9C1, 0XF881, 0X3840, 0X2800, 0XE8C1, 0XE981, 0X2940,
          0XEB01, 0X2BC0, 0X2A80, 0XEA41, 0XEE01, 0X2EC0, 0X2F80, 0XEF41, 0X2D00, 0XEDC1,
          0XEC81, 0X2C40, 0XE401, 0X24C0, 0X2580, 0XE541, 0X2700, 0XE7C1, 0XE681, 0X2640,
          0X2200, 0XE2C1, 0XE381, 0X2340, 0XE101, 0X21C0, 0X2080, 0XE041, 0XA001, 0X60C0,
          0X6180, 0XA141, 0X6300, 0XA3C1, 0XA281, 0X6240, 0X6600, 0XA6C1, 0XA781, 0X6740,
          0XA501, 0X65C0, 0X6480, 0XA441, 0X6C00, 0XACC1, 0XAD81, 0X6D40, 0XAF01, 0X6FC0,
          0X6E80, 0XAE41, 0XAA01, 0X6AC0, 0X6B80, 0XAB41, 0X6900, 0XA9C1, 0XA881, 0X6840,
          0X7800, 0XB8C1, 0XB981, 0X7940, 0XBB01, 0X7BC0, 0X7A80, 0XBA41, 0XBE01, 0X7EC0,
          0X7F80, 0XBF41, 0X7D00, 0XBDC1, 0XBC81, 0X7C40, 0XB401, 0X74C0, 0X7580, 0XB541,
          0X7700, 0XB7C1, 0XB681, 0X7640, 0X7200, 0XB2C1, 0XB381, 0X7340, 0XB101, 0X71C0,
          0X7080, 0XB041, 0X5000, 0X90C1, 0X9181, 0X5140, 0X9301, 0X53C0, 0X5280, 0X9241,
          0X9601, 0X56C0, 0X5780, 0X9741, 0X5500, 0X95C1, 0X9481, 0X5440, 0X9C01, 0X5CC0,
          0X5D80, 0X9D41, 0X5F00, 0X9FC1, 0X9E81, 0X5E40, 0X5A00, 0X9AC1, 0X9B81, 0X5B40,
          0X9901, 0X59C0, 0X5880, 0X9841, 0X8801, 0X48C0, 0X4980, 0X8941, 0X4B00, 0X8BC1,
          0X8A81, 0X4A40, 0X4E00, 0X8EC1, 0X8F81, 0X4F40, 0X8D01, 0X4DC0, 0X4C80, 0X8C41,
          0X4400, 0X84C1, 0X8581, 0X4540, 0X8701, 0X47C0, 0X4680, 0X8641, 0X8201, 0X42C0,
          0X4380, 0X8341, 0X4100, 0X81C1, 0X8081, 0X4040
      };
   
      //==========================================================================//
      // 
      //==========================================================================//
      public static int GetCrc_Fast(byte[] buf, int len)
      {
              int icrc = 0xFFFF;
              for(int i = 0; i < len; i++)
              {
                  icrc = (icrc >> 8 ) ^ CRCTable[(icrc ^ buf[i]) & 0xff];
              }
              return icrc;
      }

      // Compute the MODBUS RTU CRC, version 1. 
      public static int GetCRC(byte[] buf, int len)
      {
        UInt16 crc = 0xFFFF;
        
        for (int pos = 0; pos < len; pos++) {
          crc ^= (UInt16)buf[pos];          // XOR byte into least sig. byte of crc
        
          for (int i = 8; i != 0; i--) {    // Loop over each bit
            if ((crc & 0x0001) != 0) {      // If the LSB is set
              crc >>= 1;                    // Shift right and XOR 0xA001
              crc ^= 0xA001;
            }
            else                            // Else LSB is not set
              crc >>= 1;                    // Just shift right
          }
        }
        //byte[] crc_bytes = BitConverter.GetBytes(crc);  
        return crc;
      }
  }
```

Here's the PowerShell section

```powershell
  function Get-CRCModRTU {
      <#
          .SYNOPSIS
              Calculate CRC using the C# ModRTY implementation
          .DESCRIPTION
              Calculate CRC using the C# ModRTY implementation 
          .EXAMPLE
              Get-CRCModRTUFast $data
          .INPUTS
              byte[]
          .OUTPUTS
              uint32
      #>
      [CmdletBinding(SupportsShouldProcess)]
      param (
          # Array of Bytes to use for CRC calculation
          [Parameter(Mandatory=$true, Position = 0)]
          [ValidateNotNullOrEmpty()]
          [byte[]]$Bytes
      )

      Begin {
          if (!("ModRTU_CRC" -as [type])) {
              Write-Verbose "Registering ModRTU_CRC... " 
              try{
                  Add-Type "$Script:CsSource"
              }catch{}
          }   
      }
      process{
        try{
          Write-Verbose "[Get-CRCModRTU] clone data"
          [byte[]]$dataArray = $Bytes.Clone()
          [uint32]$inputLength = $dataArray.Length
          Write-Verbose "[Get-CRCModRTU] GetCrc (len $inputLength bytes)"
          [uint32]$crc_value =  [ModRTU_CRC]::GetCRC($dataArray, $inputLength)
          Write-output $crc_value 
        }catch{
          Write-Error "$_"
        } 
      }
  }

  function Get-CRCModRTUFast {
      <#
          .SYNOPSIS
              Calculate CRC using the C# ModRTY implementation
          .DESCRIPTION
              Calculate CRC using the C# ModRTY implementation (fast)
          .EXAMPLE
              Get-CRCModRTUFast $data
          .INPUTS
              byte[]
          .OUTPUTS
              uint32
      #>
      [CmdletBinding(SupportsShouldProcess)]
      param (
          # Array of Bytes to use for CRC calculation
          [Parameter(Mandatory=$true, Position = 0)]
          [ValidateNotNullOrEmpty()]
          [byte[]]$Bytes
      )

      Begin {
          if (!("ModRTU_CRC" -as [type])) {
              Write-Verbose "Registering ModRTU_CRC... " 
              try{
                  Add-Type "$Script:CsSource"
              }catch{}
          }   
      }
      process{
        try{
          Write-Verbose "[Get-CRCModRTUFast] clone data"
          [byte[]]$dataArray = $Bytes.Clone()
          [uint32]$inputLength = $dataArray.Length
          Write-Verbose "[Get-CRCModRTUFast] GetCrc_Fast (len $inputLength bytes)"
          [uint32]$crc_value =  [ModRTU_CRC]::GetCrc_Fast($dataArray, $inputLength)
          Write-output $crc_value 
        }catch{
          Write-Error "$_"
        } 
      }
  }
```

-------------------

## Wrapper Function

this function gets a file name and retrieves the bytes to process in other CRC functions

```powershell

  function Get-FileCRC32 {
      <#
          .SYNOPSIS
              Calculate CRC of a file.
          .DESCRIPTION
              This function calculates the CRC of the input file using the CRC32 algorithm.
          .EXAMPLE
              Get-FileCRC32 $path
          .INPUTS
              string
          .OUTPUTS
              uint32
      #>
      [CmdletBinding(SupportsShouldProcess)]
      param (
          # Array of Bytes to use for CRC calculation
          [Parameter(Mandatory=$true, Position = 0)]  
          [ValidateScript({
              if(-Not ($_ | Test-Path) ){
                  throw "File or folder does not exist"
              }
              if(-Not ($_ | Test-Path -PathType Leaf) ){
                  throw "The Destination Path argument must be a file. Directory paths are not allowed."
              }
              return $true 
          })]
          [string]$Path,
          [ValidateSet('Block32','ModRTU','ModRTUFast')]
          [string]$Algorithm='Block32'
      )
      begin{
          Write-Verbose "[Get-FileCRC32] ReadAllBytes start (`"$Path`")"
          # Portable Get-Content to bytes, the .NET is faster a bit
          [byte[]] $file_bytes = [System.IO.File]::ReadAllBytes("$Path")
          Write-Verbose "[Get-FileCRC32] ReadAllBytes done ($($file_bytes.Length) bytes)"
      }   
      process{
        try{
          [uint32]$crc = 0
          switch($Algorithm){
              'Block32'       { [uint32]$crc = Get-CRC32 $file_bytes }
              'ModRTU'        { [uint32]$crc = Get-CRCModRTU $file_bytes }
              'ModRTUFast'    { [uint32]$crc = Get-CRCModRTUFast $file_bytes }
              default         { [uint32]$crc = Get-CRC32 $file_bytes }
          }
          
          return $crc
        }catch{
          write-error "$_"
        } 
      }
  }
```

-------------------


## Performance Test Results


<br>


<center>
<img src="https://arsscriptum.github.io/assets/img/posts/powershell-crc/test.png" alt="table" />
</center>
<br>


-------------------


<br>


## Get the code 

[Crc32 on PowerShell.Public.Sandbox GitHub](https://github.com/arsscriptum/PowerShell.Public.Sandbox/tree/master/Crc32)

[Crc32 on PowerShell.Reddit.Support GitHub](https://github.com/arsscriptum/PowerShell.Reddit.Support/tree/master/Crc32)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL to guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**