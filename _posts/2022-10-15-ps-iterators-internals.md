---
layout: post
title:  "PowerShell Iterators Internals Tests"
summary: "Some notes on powershell iterators"
author: guillaume
date: '2022-10-15'
category: ['powershell','scripts', 'system']
tags: powershell, scripts, system
thumbnail: /assets/img/posts/posh-iterators/1.png
keywords: system, powershell
usemathjax: false
permalink: /blog/posh-iterators/

---

### PowerShell Iterators 

When doing an iteration with a ```ForEach``` loop, internally, at every loop the ```get_Current()``` is called.

See this statement:
```powershell
    foreach (V v in x) {scriptblock}
```

Translate to this:

```csharp
    E e = X.GetEnumerator();
    try {
        T o;
        while (e.MoveNext()) {
            o = e.Current;
            {scriptblock}
        }
    }
    finally {
        … // Dispose e
    }
```


---------------------------------------------------------------------------------------------------------

#### Order Execution 

Suppose you want to loop in a collection, but need to initialize some data before the loop, it can be done in ```GetEnumerator()```

Let's create a small collection:

```powershell

    Class T : Collections.IEnumerator{
        [System.Collections.IEnumerator]GetEnumerator() {
                $a = @(1,2,3)
                $a | % { Write-Host "__T::IEnumerator::GetEnumerator $_" }
                # Add Logic here...
                return $a.GetEnumerator()
            }
        [Int]$count = 0
        [Object]Clone(){ return [T]@{count=$this.count} }
        [void]Reset(){ $this.count = 0 }
        [bool]MoveNext(){ return ++$this.count -lt 4 }
        [Object]get_Current(){
            Write-Host "T::IEnumerator get_Current $($this.count)"
            return $this.count 
        }
    }

```

If you put a ```write-host``` in ```get_Current()``` you will get an 'interlaced' output.

```powershell

    ForEach($i in [T]::new()){
        Write-Host "ForEach Script Loop #$i"
    }

```
Outputs this:

```bash
	T::IEnumerator get_Current 1
	ForEach Script Loop #1
	T::IEnumerator get_Current 2
	ForEach Script Loop #2
	T::IEnumerator get_Current 3
	ForEach Script Loop #3
```

Whereas looping using ```GetEnumerator()``` : 

```powershell
    ForEach($i in [T]::new().GetEnumerator()){
        Write-Host "ForEach Script Loop #$i"
    }
```

Outputs this:


```bash
	__T::IEnumerator::GetEnumerator 1
	__T::IEnumerator::GetEnumerator 2
	__T::IEnumerator::GetEnumerator 3
	ForEach Script Loop #1
	ForEach Script Loop #2
	ForEach Script Loop #3
```

So for data initialization before looping in said data, it can be done in ```GetEnumerator()``` .
All pre-loop evaluation is be done in ```GetEnumerator()``` . If you add dynamic custom logic, do it there.


---------------------------------------------------------------------------------------------------------

#### Sample Custom Collection 

```powershell
    class __FooBar : System.Collections.IEnumerator {
        [int]$_count = 0
        [int]$_size = 0
        [object]get_Current() {
            return $this._count
        }

        [bool]MoveNext(){ 
            $this._count++; 
            return ($this._count -lt $this._size); 
        }
        [void] Log([string]$str) {
            $s = "[__FooBar 0x{0:x}]" -f [int]$this.GetHashCode()
            Write-Host "$s" -f DarkRed -n
            Write-Host "::$str" -f DarkYellow
        }
        [void] Reset() {
            $this._size = 0
            $this._count = 0
        }

        [void] Dispose() {
            # Do nothing
        }
        __FooBar(){ 
            #$this.Log("__FooBar()")
        }
    }

    class FooBar : __FooBar, System.Collections.Generic.IEnumerator[int] {
        FooBar([int]$size){ 
            $this._size = $size
        }
        [int]get_Current() {
            return $this._count
        }
    }
```

Looping with 


```powershell

    function Test-foreach{
        $StopWatch = [system.diagnostics.stopwatch]::StartNew()
        ForEach($i in [FooBar]::new(500)){
            
        }
        $StopWatch.Stop()
        return $StopWatch.Elapsed.TotalMilliseconds
    }
    function Test-foreachobject{
        $StopWatch = [system.diagnostics.stopwatch]::StartNew()
        [FooBar]::new(500) | foreach-object {
            
        }
        $StopWatch.Stop()
        return $StopWatch.Elapsed.TotalMilliseconds
    }


    Write-Host "==================" -f DarkRed
    Write-Host "   Test-foreach   " -f DarkYellow
    Write-Host "==================" -f DarkRed
    $v1=Test-foreach
    $v2=Test-foreachobject
    "Test-foreach      `t{1:n5}ms`nTest-foreachobject`t{2:n5}ms`n------`nDiff fe/feo`t`t{3:n5}ms" -f $v0,$v1, $v2, ($v1-$v2)
```

```bash
    Test-foreach            15.60630ms
    Test-foreachobject      8.18050ms
    ------
    Diff fe/feo             7.42580ms
```

This Collection inheriting from IEnumerator and IEnumerable

```powershell
        
    class __FooBar : System.Collections.IEnumerator,System.Collections.IEnumerable {
        [int]$_count = 0
        [int]$_size = 0
        [System.Collections.Generic.List[int]]$_list =  [System.Collections.Generic.List[int]]::new()
        [object]get_Current() {
            return $this._count
        }
        [System.Collections.IEnumerator]GetEnumerator() {
            return $this._list.GetEnumerator()
        }
        [bool]MoveNext(){ 
            $this._count++; 
            return ($this._count -lt $this._size); 
        }
        [void] Log([string]$str) {
            $s = "[__FooBar 0x{0:x}]" -f [int]$this.GetHashCode()
            Write-Host "$s" -f DarkRed -n
            Write-Host "::$str" -f DarkYellow
        }
        [void] Reset() {
            $this._count = 0
        }
        [void] Init([int]$size) {
            $this._size = $size
            0..$this._size | % { $this._list.Add($_) }
        }
        [void] Dispose() {
            # Do nothing
        }
        __FooBar(){
            
        }
    }

      class FooBar : __FooBar, System.Collections.Generic.IEnumerator[int] {
        FooBar([int]$size){ $_size = $size ; Write-Host "CONSTRUCTOR FooBar" ; $this.Init($size)}
        [int]get_Current() {
            return $this._count
        }
    }

```

Iterate with :


```powershell
        $toBeIterated = [FooBar]::new(500)
        ##################################
        # Iteration Loop Model 1
        [Collections.IEnumerable]$iEnumerableOftoBeIterated = $toBeIterated

        foreach($element in $iEnumerableOftoBeIterated){
           Write-Host "Current value is $element"
        }

        $toBeIterated.Reset()

        ##################################
        # Iteration Loop Model 2

        [Collections.IEnumerator] $iEnumeratorOftoBeIterated = $toBeIterated.GetEnumerator();

        while ($iEnumeratorOftoBeIterated.MoveNext()){
            Write-Host "Current value is $($iEnumeratorOftoBeIterated.Current)"

        }    
```