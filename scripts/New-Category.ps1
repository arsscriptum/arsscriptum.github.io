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
$Script:TemplateCategoryFile            = Join-Path $TemplatePath "category.txt.tpl"
$Script:CategoriessPath                 = Join-Path $Script:WebRootPath "categories"
$SublimeTextPath = Get-SublimeTextPath


$AllPostsFiles = Get-ChildItem -Path "$Script:PostsPath" -File -Filter "*.md"

$AllCategories = "`$CategoryList = @("
ForEach($file in $AllPostsFiles.Fullname){
	
	[String[]]$PostContent = Get-Content $file
	$Categories = $PostContent[6]
	if($Categories -notmatch 'category: \['){
		Write-Host "Failed to find categories for file `"$file`" " -f DarkYellow
		continue;
	}
	$Categories = $PostContent[6].Replace('category: [','').Replace(']',',')
	$AllCategories += $Categories
}
$AllCategories = $AllCategories.TrimEnd(',')
$AllCategories = $AllCategories += ')'
Invoke-Expression -Command $AllCategories
$UniqueCategories = $CategoryList | Select -Unique
$CategoryListCount = $CategoryList.Count
$UniqueCategoriesCount = $UniqueCategories.Count
Write-Host "Found $CategoryListCount categories. $UniqueCategoriesCount Unique"



ForEach($cat in $UniqueCategories){
	Write-Host "[CATEGORY] " -n -f DarkGray
	Write-Host "$cat " -n -f Gray
	$FullCatFilePath = "{0}\{1}.md" -f "$Script:CategoriessPath", "$cat"
	if($Force){
		$Null = Remove-Item -Path "$FullCatFilePath" -Force -ErrorAction Ignore
		$NewFileContent = Get-Content "$Script:TemplateCategoryFile" -Raw
		Write-Host "Refreshing category file. " -n -f DarkCyan
		$NewFileContent = $NewFileContent.Replace('__CATEGORY_NAME__', "$cat")
		Set-Content "$FullCatFilePath" $NewFileContent -Force
		Write-Host "new `"$FullCatFilePath`" " -f DarkGreen
	}elseif(Test-Path "$FullCatFilePath"){
		Write-Host "Found category file `"$FullCatFilePath`" " -f DarkGreen
		continue;
	}
	else{
		$NewFileContent = Get-Content "$Script:TemplateCategoryFile" -Raw
		Write-Host "Missing category file. " -n -f DarkYellow
		$NewFileContent = $NewFileContent.Replace('__CATEGORY_NAME__', "$cat")
		Set-Content "$FullCatFilePath" $NewFileContent -Force
		Write-Host "added `"$FullCatFilePath`" " -f DarkGreen
	}


}