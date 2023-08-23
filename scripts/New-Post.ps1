<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

#===============================================================================
# Commandlet Binding
#===============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Force") ]
    [Alias('f')]
    [switch]$Force
    
)

function Get-Script([string]$prop){
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile)|select $prop).$prop
}

$Script:ScriptPath                      = split-path $script:MyInvocation.MyCommand.Path
$Script:ScriptFullName                  = (Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName
$Script:WebRootPath                     = (Resolve-Path "$Script:ScriptPath\..").Path
$Script:ModuleName                      = (Get-Item -Path $Script:WebRootPath).Name
$Script:CurrPath                        = $ScriptPath
$Global:CurrentRunningScript            = Get-Script basename
$Script:Time                            = Get-Date
$Script:TemplatePath                    = Join-Path $ScriptPath "template"
$Script:PngImage                        = Join-Path $Script:TemplatePath "1.png"
$Script:PostsPath                       = Join-Path $Script:WebRootPath "_posts"
$Script:ImgPath                         = Join-Path $Script:WebRootPath "assets\img"
$Script:PostImgPath                     = Join-Path $Script:ImgPath "posts"
$Script:TemplatePostFile                = Join-Path $TemplatePath "post.txt.tpl"
$Script:PostsPath
$SublimeTextPath = Get-SublimeTextPath

$Title = Read-Host 'Post Title'
$Summary = Read-Host 'Post Summary'

Write-Host "Get the post date, in this format 2022-01-30  " -n -f Red
$PostDate = Read-Host 'Date'
Write-Host "Get the post link (powershell-progressbar)  " -n -f Red
$PostLink = Read-Host 'Link'

$Script:PostFilePath = "$Script:PostsPath\{0}-{1}.md" -f $PostDate, $PostLink

Copy-Item $Script:TemplatePostFile $Script:PostFilePath


$ImageDirectory = Join-Path $Script:PostImgPath $PostLink 
$Null = New-Item -Path $ImageDirectory -ItemType Directory -Force -ErrorAction Ignore
$PngPost = Join-Path $ImageDirectory "1.png"
Copy-Item $Script:PostsPath $PngPost



$Content = Get-Content $Script:PostFilePath -Raw

$Content = $Content.Replace('__TITLE__',$Title)
$Content = $Content.Replace('__LINK__',$PostLink)
$Content = $Content.Replace('__SUMMARY__',$Summary)
$Content = $Content.Replace('1909-09-09',$PostDate)

Set-Content -Path $Script:PostFilePath -Value $Content
&"$SublimeTextPath" $Script:PostFilePath
