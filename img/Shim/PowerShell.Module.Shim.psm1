<#̷#̷\
#̷\ 
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\    
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#̷\
#̷\   Generated on Tue, 28 Dec 2021 04:36:32 GMT 
#̷\
#̷##>



#Requires -Version 5
Set-StrictMode -Version 'Latest'
# ------------------------------------
# Script file - Helpers - 
# ------------------------------------
$ScriptBlockHelpers = "H4sIAAAAAAAACsVVXW/aMBR9j5T/YNFITSRA3WslHjYKbaXxsYSpm1AkvOQC1ozNbEcMIf777HxAAqGdtq5LHuz4Hl/fc+/xjW3Z+o0olhJ1l5gxoGPB1yAUAWlbO9tC+rmqMZn1qVSCsEXo5HbUQdfBw+PgOjd3OZOcQpdTLkJnQlQ+N7ivQCnf1CMHICVeHLF3WHy/F3hbj+4JwUUF60NcDw2SKNK+TxwDsGc834GMBFkrwlll34HA3race8q/YXpbypPUuOlZ3sLbWwYb1zNZt615wiLjFz0JoqCVo3P2OxNQ6blCw1Hvy3jkT/RHEe4qpqA+EBbrMrhBsl5zoWSw5AmN9aGGqxdm2DUWeOVm83Tv2CyAAuEOMIux4mLbcZRIoDnmkpiwOjfF5kqx8/iK9QyRMjKTjMoDlwo1po5bl5l2/uGFqIFac3QBddSLh1pDPoTNR8Lg/JQioOd8lRXlpSW7nH8fZELVafrr61DKwH8tRrNs2hAVLUPnCQumMSf1IXO3sKAW/EBOH1MJXn7TX7eC5et2XsPTs1DwudvtBcFfuNyD5vJPqBybzG8Q6fn+yH/Z3WlnqeGTDa+p+UuqTyPavSx29Baqr0g92EoFq7aGaDYrYKr9PlF8hQ2HLJE+RFzEoZONB8GbwZlzoaHZddEtubG72c/Y7t2+UdgJ0Ng063x3u59Quv2UYEq0KU79P8bNwtr7GUFasfaEB6lT08xTT5lpIBcdt3pqS5coOyaHvn2PnKaS/HOJV7R3IDpjM6Y99rmAheAJi7Mf5PHvmKrO+gVJDew0ZQgAAA=="

# ------------------------------------
# Script file - Shims - 
# ------------------------------------
$ScriptBlockShims = "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"



# ------------------------------------
# Loader
# ------------------------------------
function ConvertFrom-Base64CompressedScriptBlock {

    [CmdletBinding()] param(
        [String]
        $ScriptBlock
    )

    # Take my B64 string and do a Base64 to Byte array conversion of compressed data
    $ScriptBlockCompressed = [System.Convert]::FromBase64String($ScriptBlock)

    # Then decompress script's data
    $InputStream = New-Object System.IO.MemoryStream(, $ScriptBlockCompressed)
    $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    $StreamReader = New-Object System.IO.StreamReader($GzipStream)
    $ScriptBlockDecompressed = $StreamReader.ReadToEnd()
    # And close the streams
    $GzipStream.Close()
    $InputStream.Close()

    $ScriptBlockDecompressed
}

# For each scripts in the module, decompress and load it.

$ScriptList = @('Helpers','Shims')
$ScriptList | ForEach-Object {
    $ScriptId = $_
     $ScriptBlock = "`$ScriptBlock$($ScriptId)" | Invoke-Expression
    $ClearScript = ConvertFrom-Base64CompressedScriptBlock -ScriptBlock $ScriptBlock
    try{
        $ClearScript | Invoke-Expression
    }catch{
        Write-Host "===============================" -f DarkGray
        Write-Host "$ClearScript" -f DarkGray
        Write-Host "===============================" -f DarkGray
        Write-Error "ERROR IN script $ScriptId . Details $_"
    }
}




