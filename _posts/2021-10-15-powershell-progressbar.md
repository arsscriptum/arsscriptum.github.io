---
layout: post
title:  "Fun with PowerShell's Progress Bar"
summary: "Create your own Custom Progress Bar in PowerShell"
author: guillaume
date: '2021-10-15'
category: ['powershell','scripts', 'useless']
tags: powershell, scripts, useless
thumbnail: /assets/img/posts/custom-progressbar/1.png
keywords: progress, powershell
usemathjax: false
permalink: /blog/powershell-progressbar/

---

Day after day, night after night, writing PowerShell scripts. It is inevitable, you will become a p0w325h311 31173 c0d32.
Your scripts will become more complex and will take more time to complete. Logs only go so far, while you wait for the completion 
of your scripts, you'll need a progress / activity indicator.

This can be achievable by using ```Write-Progress``` cmdlet which Displays a progress bar within a Powershell command window. 
Unfortunately that function comes with it's own disadvantages. In this article, we implement our own progress bar for our scripts.

---------------------------------------------------------------------------------------------------------

#### Rationale 

Before going any further, let me just explain why the progress bar provided in PowerShell isn't perfectly suited for us.

#### Write-Progress 

This cmdlet provided in PowerShell may be included as a few lines of code, wrapped as a function to be used repeatedly throughout a script, 
or mixed in with variables to minimize code duplication.

<mark>Pros</mark> Ease of use. Lots of information provided to the user.

<mark>Cons</mark> The huge screen real-estate reserved for the progress bar when in use: nearly 1/8th of the screen. Moreover, the display
may hide some important script outputs and you can't do anything about it. <p><strong>Performance: </strong></p> even though the implementation
is purely native; each call to ```Write-Progress``` will do some processing, rendering so the user must be extra carefull with how he uses
Write-Progress * <p><small>I will come back on this subject later with a more detailed explanation and comparison with a custom implentation.</small></p>

### The advantages of rolling our own  </h3>

<mark>Pros</mark> Aesthetics: i'm a sucker for ascii-based menus and progress bars. Those are more pretty. Moreover we can make it so the size and position
of our progress bar is customizable, smaller than the natively provided cmdlet, it is only a single line of text, at the current cursor position, 
and does not hide any output or status messages from other commands. 

<p><strong>Performance: </strong></p> using a ```RefreshDelay``` and a ```GUI update delay``` improves the performance by having the progress logic to only 
be processed every time the GUI is updated, and we control when the GUI is updated.


---------------------------------------------------------------------------------------------------------


### The Basics </h3>

- New-AsciiProgressBar - Used to initialize the ProgressBar variables attached to progressbar. Counters and Threading related variables. 
- Write-AsciiProgressBar - Used to send progress events to the ProgressBar.  
- Close-AsciiProgressBar - Used to deinitialize the ProgressBar cleanly.


### Implementation Details </h3>

Our ascii-based progress bar requires a way to output to console at specified position and color: ```Write-ConsoleExtended```

#### Requirements  Write-ConsoleExtended 




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


#### Start-AsciiProgressBar


```powershell

	function Start-AsciiProgressBar{
	<#
	.SYNOPSIS
	    Initialize the Ascii Progress Bar
	.DESCRIPTION
	    Initialize the Ascii Progress Bar by seting the size of the bar in characters. If you set the EstimatedSeconds
	    value, there will e a countdown timer in the progress bar.
	.PARAMETER EstimatedSeconds
	    The estimated time of the job that will be refreshing the progress bar. If this is set there will be a countdown
	    timer in the progress message
	.PARAMETER Size
	    The size of the progress bar in characters
	.PARAMETER EmptyChar
	    The character used in the progress bar
	.PARAMETER FullChar
	    The character used in the progress bar
	.EXAMPLE
	    Initialize-AsciiProgressBar 30 
	    Initialize the progress bar with default settings, no countdown timer sizr of 30 character
	.EXAMPLE
	    Initialize-AsciiProgressBar 30 30
	    Initialize the progress bar so that it will diaplay a countdown timer for 30 seconds

	.NOTES
	    Author: Guillaume Plante
	    Last Updated: October 2022
	#>


	    [CmdletBinding()]
	    Param(
	        [Parameter(Mandatory = $false,Position=0, HelpMessage="The estimated time the process will take")]
	        [int]$EstimatedSeconds=0,
	        [Parameter(Mandatory = $False,Position=1, HelpMessage="The size of the progress bar")] 
	        [int]$Size=30,
	        [Parameter(Mandatory = $False,Position=2, HelpMessage="Empty char in the ascii progress bar")]
	        [char]$EmptyChar = '-',
	        [Parameter(Mandatory = $False,Position=3, HelpMessage="Full char in the ascii progress bar")]
	        [char]$FullChar = 'O'
	    )

	    $Script:CurrentSpinnerIndex = 0
	    $Script:Max = $Size
	    $Script:Half = $Size/2
	    $Script:Index = 0
	    $Script:Pos=0
	    $Script:EstimatedSeconds = $EstimatedSeconds
	    $Script:EmptyChar = $EmptyChar
	    $Script:FullChar = $FullChar
	    $Script:progressSw.Start()
	    [Datetime]$Script:StartTime = [Datetime]::Now
	    $e = "$([char]27)"
	    #hide the cursor
	    Write-Host "$e[?25l"  -NoNewline  
	}

```



#### Write-AsciiProgressBar

<p>Now to build the meat. The central. The <strong>Write-AsciiProgressBar</strong> function.</p>



```powershell

	function Write-AsciiProgressBar{

	<#
	.SYNOPSIS
	    Displays the completion status for a running task.
	.DESCRIPTION
	    Show-AsciiProgressBar displays the progress of a long-running activity, task, 
	    operation, etc. It is displayed as a progress bar, along with the 
	    completed percentage of the task. It displays on a single line (where 
	    the cursor is located). As opposed to Write-Progress, it doesn't hide 
	    the upper block of text in the PowerShell console.
	.PARAMETER Percentage
	    Completion percentage
	.PARAMETER UpdateDelay
	    The 'refresh' interval for the update of the progress bar. This will **not** sleep.
	    If the function is called 100 times per seconds and the UpdateDelay is 100, the progress bar will be
	    refreshed once every 100 milliseconds, **not** 100*seconds 
	.PARAMETER ProgressDelay
	    Amount of time between two 'refreshes' of the percentage complete and update
	    of the progress bar. This is a sleep in the function. Default is 5 ms
	.PARAMETER ForegroundColor
	    Foreground color for the message
	.PARAMETER BackgroundColor
	    Background color for the message

	.EXAMPLE
	    Show-AsciiProgressBar
	    Without any arguments, Show-AsciiProgressBar displays a progress bar refreshing at every 100 milliseconds.
	    If no value is provided for the Activity parameter, it will simply say 
	    "Current Task" and the completion percentage.
	.EXAMPLE
	    Show-AsciiProgressBar 50 5 "Yellow"
	    Displays a progress bar refreshing at every 50 milliseconds in Yellow color
	.NOTES
	    Author: Guillaume Plante
	    Last Updated: October 2022
	#>


	    [CmdletBinding()]
	    Param(
	        [Parameter(Mandatory = $True,Position=0, HelpMessage="Completion percentage.")]
	        [ValidateRange(0, 100)]
	        [int]$Percentage,
	        [Parameter(Mandatory = $false,Position=1, HelpMessage="Completion percentage.")]
	        [string]$Message="",
	        [Parameter(Mandatory = $false,Position=2, HelpMessage="The interval at which the progress will update.")]
	        [int]$UpdateDelay=100,
	        [Parameter(Mandatory = $False,Position=3, HelpMessage="The delay this function will sleep for, in ms. Used to replace the sleed in calling job")] 
	        [int]$ProgressDelay=5,
	        [Parameter(Mandatory = $False,Position=4, HelpMessage="Foreground color for the message")] 
	        [Alias('f')]
	        [System.ConsoleColor] $ForegroundColor = [System.Console]::ForegroundColor,
	        [Parameter(Mandatory = $False,Position=5, HelpMessage="Background color for the message")] 
	        [Alias('b')]
	        [System.ConsoleColor] $BackgroundColor = [System.Console]::BackgroundColor
	    )

	    $ms = $Script:progressSw.Elapsed.TotalMilliseconds
	    if($ms -lt $UpdateDelay){
	        return
	    }

	    $spinners = @( "-","\","|","/")
	    $Script:CurrentSpinnerIndex++
	    if($Script:CurrentSpinnerIndex -ge $spinners.Count){
	        $Script:CurrentSpinnerIndex = 0
	    }
	    $CurrentSpinner = $spinners[$Script:CurrentSpinnerIndex]

	    $ElapsedSeconds = [Datetime]::Now - $Script:StartTime
	    $Script:progressSw.Restart()
	   
	    $Script:Pos = [math]::Round(($Script:Max / 100) * $Percentage)
	    

	    $str = ''
	    For($a = 0 ; $a -lt $Script:Pos ; $a++){
	        $str += "$Script:FullChar"
	    }
	    $str += $CurrentSpinner
	    For($a = $Script:Pos ; $a -lt $Script:Max ; $a++){
	        $str += "$Script:EmptyChar"
	    }

	    $ElapsedTimeStr = ''

	    $secsofar =  $Script:EstimatedSeconds - $ElapsedSeconds.TotalSeconds
	    $ts =  [timespan]::fromseconds($secsofar)
	    if($ts.Ticks -gt 0){
	        $ElapsedTimeStr = "{0:mm:ss}" -f ([datetime]$ts.Ticks)
	    }
	    $ProgressMessage = "Progress: [{0}] {1} {2}" -f $str, $ElapsedTimeStr, $Message
	    Write-ConsoleExtended "$ProgressMessage" -ForegroundColor "$ForegroundColor" -BackgroundColor "$BackgroundColor"  -Clear -NoNewline
	    Start-Sleep -Milliseconds $ProgressDelay
	}

```


#### Stop-AsciiProgressBar

<p>The <strong>Stop-AsciiProgressBar</strong> function is going to be very similar.</p>

---------------------------------------------------------------------------------------------------------


### How to Use  </h3>

I have provided a simple code block with a [dummy PowerShell Job](https://github.com/arsscriptum/PowerShell.CustomProgressBar/blob/main/Start-DummyJob.ps1)
making uses of the ascii progress bar.


#### Start-AsciiProgressBar 

This function is called **once**, before the job is started. Initialize the progress bar with default settings, no countdown timer sizr of 30 character


Initialize the progress bar so that it will diaplay a constructortdown timer for 30 seconds



```powershell
    Write-ActivityIndicatorBar
```


Called at every iteration of the loop
Shows an animation to represent activity in the job


#### Write-AsciiProgressBar 


```powershell
    Write-AsciiProgressBar
```


Called at every iteration of the loop
Without any arguments, Write-AsciiProgressBar displays a progress bar refreshing at every 100 milliseconds.
If no value is provided for the Activity parameter, it will simply say "Current Task" and the completion percentage.



```powershell
    Write-AsciiProgressBar 50 5 "Yellow"
```

Displays a progress bar refreshing at every 50 milliseconds in Yellow color


---------------------------------------------------------------------------------------------------------


### Example  </h3>

You can use Get-Help to view the help for the function or use the switch -Examples to see some usage examples from the function's native help. Of course, the best way to test and understand Show-Progress is to put it to work. Let's look at a few usage scenarios.

Use the provided dummy job code for example


```powershell
    Get-Help Write-AsciiProgressBar -Examples
```


Start a dummy job with ASCII progress bar


```powershell

	. .\Start-DummyJob.ps1 10

```



---------------------------------------------------------------------------------------------------------



#### Activity Indicator 


<img class="card-img-top-restricted-60"
     src="/assets/img/posts/custom-progressbar/ActivityIndicator.gif"
     alt="Activity Indicator" />



---------------------------------------------------------------------------------------------------------



#### Progress Bar 


<img class="card-img-top-restricted-60"
     src="/assets/img/posts/custom-progressbar/ProgressWheel.gif"
     alt="Progress Bar" />



---------------------------------------------------------------------------------------------------------




#### Progress Bar Demo 


<img class="card-img-top-restricted-60"
     src="/assets/img/posts/custom-progressbar/ProgressWheelDemo.gif"
     alt="Progress Bar Demo" />




--------------------------------------------------------------------------------------------------------


## Get the code 


[PowerShell.CustomProgressBar on GitHub](https://github.com/arsscriptum/PowerShell.CustomProgressBar)

***Important Note*** Do You have Issues accessing the core repository? **Don't be shy and send me an** [EMAIL at guillaumeplante.qc@gmail.com](mailto:guillaumeplante.qc@gmail.com) **and I will fix access for you**