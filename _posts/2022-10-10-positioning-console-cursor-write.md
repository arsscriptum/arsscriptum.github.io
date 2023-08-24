---
layout: post
title:  "Positioning the PowerShell Console Cursor with Write-Host"
summary: "PowerShell console supports VT escape sequences that can be used to position and format console text. An overview."
author: guillaume
date: '2022-10-10'
category: ['powershell','scripts', 'console']
tags: powershell, scripts, console
thumbnail: /assets/img/posts/console-cursor/1.png
keywords: console, powershell
usemathjax: false
permalink: /blog/console-cursor/

---

#### Positioning the PowerShell Console Cursor with Write-Host 

The PowerShell console supports VT escape sequences that can be used to position and format console text. Note that this works in the console only, not the PowerShell ISE. Note also that you either need Windows 10 or an emulator like ConEmu.

VT escape sequences can set the console cursor to any location inside the console window. To set the caret to the top left corner, for example, use this:


```powershell
	$esc = [char]27
	$setCursorTop = "$esc[0;0H"

	Write-Host "${setCursorTop}This always appears in line 0 and column 0!"

```


When you run this, the text is always located in line 0 and column 0. You can use this technique to create your own custom progress indicator – just remember: all of this works in console windows, only, not in the PowerShell ISE.



```powershell
	function Show-CustomProgress
	{
	    try
	    {
	        $esc = [char]27
	    
	        # let the caret move to column (horizontal) pos 12
	        $column = 12
	        $resetHorizontalPos = "$esc[${column}G"
	        $gotoFirstColumn = "$esc[0G"
	        
	        $hideCursor = "$esc[?25l"
	        $showCursor = "$esc[?25h"
	        $resetAll = "$esc[0m" 

	        # write the template text
	        Write-Host "${hideCursor}Processing     %." -NoNewline

	        1..100 | ForEach-Object {
	            # insert the current percentage
	            Write-Host "$resetHorizontalPos$_" -NoNewline
	            Start-Sleep -Milliseconds 100
	        }
	    }
	    finally
	    {
	        # reset display
	        Write-Host "${gotoFirstColumn}Done.              $resetAll$showCursor"
	    }
	}

```

When you run this code, then enter the command Show-CustomProgress, you’ll see an incrementing custom progress indicator. The console hides the blinking prompt. When the indicator is done, or when you press CTRL+C, the progress indicator hides, and instead the word “Done.” appears. The caret starts blinking again.


------------------------------------------------------------------------------------------------------------------------------------------------



#### Write-ConsoleExtended : Extending Write-Host 


This small function is useful in that it extends the Write-Host function an provides the ability to write a certain position, and with certain colors. I used it extensively in my [Custom-ProgressBar code](https://github.com/arsscriptum/blog/powershell-progressbar/)


```powershell
	function Write-ConsoleExtended{

	<#
	.SYNOPSIS
	    Write a string in the console
	.DESCRIPTION
	    Write a string in the console at specific position and color
	.PARAMETER Message
	    Message to be printed
	.PARAMETER PosX
	   Cursor X position where message is to be printed
	.PARAMETER PosY
	    Cursor Y position where message is to be printed
	.PARAMETER ForegroundColor
	    Foreground color for the message
	.PARAMETER BackgroundColor
	    Background color for the message
	.PARAMETER Clear
	   Clear whatever is typed on this line currently
	.PARAMETER NoNewline
	    After printing the message, return the cursor back to its initial position
	.EXAMPLE
	    Write-ConsoleExtended "MY TITLE" -x ([System.Console]::get_BufferWidth()/2) -f Red
	    Write a string in the center of screen in red
	.NOTES
	    Author: Guillaume Plante
	    Last Updated: October 2022
	#>

	    [CmdletBinding(SupportsShouldProcess)]
	    param(
	        [Parameter(Mandatory = $True, Position = 0, HelpMessage="Message to be printed")] 
	        [Alias('m')]
	        [string]$Message,
	        [Parameter(Mandatory = $False, HelpMessage="Cursor X position where message is to be printed")] 
	        [Alias('x')]
	        [int] $PosX = -1,
	        [Parameter(Mandatory = $False, HelpMessage="Cursor Y position where message is to be printed")] 
	        [Alias('y')]
	        [int] $PosY = -1,
	        [Parameter(Mandatory = $False, HelpMessage="Foreground color for the message")] 
	        [Alias('f')]
	        [System.ConsoleColor] $ForegroundColor = [System.Console]::ForegroundColor,
	        [Parameter(Mandatory = $False, HelpMessage="Background color for the message")] 
	        [Alias('b')]
	        [System.ConsoleColor] $BackgroundColor = [System.Console]::BackgroundColor,
	        [Parameter(Mandatory = $False, HelpMessage="Clear whatever is typed on this line currently")] 
	        [Alias('c')]
	        [switch] $Clear,
	        [Parameter(Mandatory = $False, HelpMessage="After printing the message, return the cursor back to its initial position.")] 
	        [Alias('n')]
	        [switch] $NoNewline
	    ) 

	    $fg_color            = [System.Console]::ForegroundColor
	    $bg_color            = [System.Console]::BackgroundColor
	    $cursor_top          = [System.Console]::get_CursorTop()
	    $cursor_left         = [System.Console]::get_CursorLeft()

	    $new_cursor_x = $cursor_left
	    if ($PosX -ge 0) { $new_cursor_x = $PosX }
	   
	    $new_cursor_y = $cursor_top
	    if ($PosY -ge 0) { $new_cursor_y = $PosY } 
	    
	    if ( $Clear ) { 
	        [int]$len = ([System.Console]::WindowWidth - 1)  
	        # use the string constructor for init a string with character 32 (space), len times
	        [string]$empty = [string]::new([char]32,$len)                       
	        
	        [System.Console]::SetCursorPosition(0, $new_cursor_y)
	        [System.Console]::Write($empty)            
	    }
	    [System.Console]::ForegroundColor = $ForegroundColor
	    [System.Console]::BackgroundColor = $BackgroundColor
	    
	    [System.Console]::SetCursorPosition($new_cursor_x, $new_cursor_y)

	    # Write the message, if NoNewline, go ack to beginning
	    [System.Console]::Write($Message)
	    if ( $NoNewline ) { 
	        [System.Console]::SetCursorPosition($cursor_left, $cursor_top)
	    }

	    # back to previous colors
	    [System.Console]::ForegroundColor = $fg_color
	    [System.Console]::BackgroundColor = $bg_color
	}

```




#### Write-ConsoleExtended : Example Usage 



```powershell
	function Write-FlashingText{
	    [CmdletBinding(SupportsShouldProcess)]
	    param(
	        [Parameter(Mandatory = $True, Position = 0, HelpMessage="Message to be printed")] 
	        [Alias('m')]
	        [string]$Message
	    ) 
	    cls
	    $e = "$([char]27)"
	    #hide the cursor
	    Write-Host "$e[?25l"  -NoNewline  
	    [int]$len = ([System.Console]::WindowWidth - 1)
	    [string]$empty = [string]::new("=",$len)
	    $cl = $True 
	    For($i = 0 ; $i -lt 100 ; $i++){ 
	        $cl = !$cl
	        $color1 = "DarkRed"
	        $color2 = "DarkYellow"

	        if($cl){ 
	            $color1 = "DarkYellow"
	            $color2 = "DarkRed"
	        }
	        cls
	        $TitleLen = $Message.Length
	        $posx = ([System.Console]::get_BufferWidth()/2) - ($TitleLen/2)
	        Write-ConsoleExtended $empty -f $color1  
	        Write-ConsoleExtended "$Message" -x $posx -y ([System.Console]::get_CursorTop()+1) -f $color2 
	        Write-ConsoleExtended "`n$empty`n" -f $color1  

	        Start-Sleep -Millisecond 500
	    }

	    #show the cursor
	    Write-Host "$e[?25h"
	}
```



#### Draw Boxes ! :) 


Here's another example, this code will draw lines, and 4 lines = a boxe :)


```powershell

	function DrawLine([int]$x, [int]$y, [int]$length,[int]$vertical){ 
	    Write-ConsoleExtended "*" $x $y -nonewline 
	    # Is this vertically drawn?  Set direction variables and appropriate character to draw 
	    If ([boolean]$vertical){ 
	        $linechar='!'; $vert=1;$horz=0
	    }else{ 
	        $linechar='-'; $vert=0;$horz=1
	    } 

	    foreach ($count in 1..($length-1)) { 
	        Write-ConsoleExtended $linechar (($horz*$count)+$x) (($vert*$count)+$y) -f DarkRed -nonewline 
	    }
	    # Bump up the counter and draw the end
	    $count++
	    Write-ConsoleExtended '*' (($horz*$count)+$x) (($vert*$count)+$y) -f DarkYellow -nonewline 
	} 


	Clear-Host

	DrawLine -x 5 -y 5 -length 5 -vertical 0
	DrawLine -x 5 -y 10 -length 5 -vertical 0
	DrawLine -x 5 -y 5 -length 5 -vertical 5
	DrawLine -x 10 -y 5 -length 5 -vertical 5


```



<center>
<img src="/assets/img/posts/console-cursor/flash.gif"  alt="important" style="height: 175px; width:775px;"/>
</center>

### Checkout this custom progress bar that makes usage of the information in this post
[PowerShell.CustomProgressBar](https://github.com/arsscriptum/blog/powershell-progressbar/)

