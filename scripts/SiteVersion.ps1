<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   SiteVersion
#̷𝓍   
#>

Class SiteVersion : IComparable {   
        # Added a GetEnumerator() Override
        [int]$Major  
        [int]$Minor  
        [int]$Build  
        [string]$Revision

        [string]ToString() {
            if($($this.Revision) -eq 0 -And $($this.RevMinor) -eq 0 -And $($this.VersionBuffer) -eq 0){ return "$($this.Major).$($this.Minor).$($this.Build)"}
                return "$($this.Major).$($this.Minor).$($this.Build).$($this.Revision)"
            }
         [bool] Equals([Object] $other) {
            #
            # Equals() is required for the -eq operator.
            #
              return $this.ToString() -eq $other.ToString()
           }

        [int] CompareTo([Object] $other) {
            #
            # CompareTo() is required for the -lt
            # and -gt operator.
            # 
            [SiteVersion]$incomingver = $other
    
            if ($incomingver -eq $null){
                return 1;
            }

            if ($this.Major -ne $incomingver.Major){
                if( $this.Major -gt $incomingver.Major) { return 1;} else{ return -1;};
            }

            if ($this.Minor -ne $incomingver.Minor){
                if( $this.Minor -gt $incomingver.Minor) { return 1;} else{ return -1;};
            }

            if ($this.Build -ne $incomingver.Build){
                if( $this.Build -gt $incomingver.Build) { return 1;} else{ return -1;};
            }

            if ($this.Revision -ne $incomingver.Revision){
                if( $this.Revision -gt $incomingver.Revision) { return 1;} else{ return -1;};
            }

            return if($this.GetHashCode() -gt $incomingver.GetHashCode())  { return 1;} else{ return -1;};
        }

        [int] GetHashCode() {
            #
            # An object that overrides the Equals() method
            # should (must?) also override GetHashCode()
            #
            return $this.ToString().GetHashCode();
        }
        [void]Default(){
            $this.Major = 0
            $this.Minor = 0
            $this.Build = 0
            $this.Revision = ''
        }

        SiteVersion(){
            $this.Default()
        }

        SiteVersion([string]$strver){
            $this.Default();
            if($strver -imatch 'Unknown'){ return; }
            $data = $strver.split('.')
            if($data.Count -eq 0){throw "SiteVersion error"}
            try{
                if($data[0] -ne $Null){ $this.Major = $data[0]}
                if($data[1] -ne $Null){ $this.Minor = $data[1]}
                if($data[2] -ne $Null){ $this.Build = $data[2]}
                if($data[3] -ne $Null){ $this.Revision = $data[3]}
            }catch{
                Write-Warning "Error in version interpreter: $_"
            }
        }
        SiteVersion([int]$ver_maj, [int]$ver_min, [int]$ver_build=0, [string]$ver_rev=''){
            $this.Default();
            try{
                $this.Major = $ver_maj
                $this.Minor = $ver_min
                $this.Build = $ver_build
                $this.Revision = $ver_rev
            }catch{
                Write-Warning "Error in version interpreter: $_"
            }
        }
}

