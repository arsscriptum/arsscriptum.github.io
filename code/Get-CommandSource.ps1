


function Get-FunctionSource1{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, HelpMessage="Function Name")]
        [string]$Name
    ) 
    $IsFunction = $True
    $CmdType = Get-Command $Name
    if($CmdType -eq $Null){ return }
    $CmdType = (Get-Command $Name).CommandType
    $Script = ""
    try{
        $Script = (Get-Item function:$Name -ErrorAction Stop).ScriptBlock
    }
    catch{
        $IsFunction = $False
    }
    
    write-host -n -f DarkYellow "Command Type  : " ;
    write-host -f DarkRed "$CmdType" ;

    if(($IsFunction -eq $False)-Or($CmdType -eq 'Alias')){
        $AliasInfo = (Get-Alias $Name).DisplayName
        write-host -n -f DarkYellow "Alias Info : " ;
        write-host -f DarkRed "$AliasInfo" ;     
        $AliasDesc = (Get-Alias $Name).Description
        write-host -n -f DarkYellow "Alias Desc : " ;
        write-host -f DarkRed "$AliasDesc" ;   
    }else{
        write-host -n -f DarkYellow "Function Name : " ;
        write-host -f DarkRed "$Name" ;
    }

    return $Script

}



function Get-CommandSource1{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, HelpMessage="Command Name (like cl.exe or LiveTcpUdpWatch.exe)")]
        [string]$Name
    ) 
     
    $Res = Get-Command $Name -ErrorAction Ignore
    if($Res){
        $Source = $($Res).Source
		if($Source){   
            return "$Source"
		}
        else{
            return (Get-FunctionSource1 $Name)
        }
    }
	return $Null
}