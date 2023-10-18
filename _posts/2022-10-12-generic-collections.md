---
layout: post
title:  "Generic Collections in PowerShell"
summary: "Learn about some generic collections that can make your life much easier"
author: guillaume
date: '2022-10-12'
category: ['powershell','scripts', 'collections', 'list', 'queue', 'stack', 'hashset']
tags: powershell, scripts, collections, list, queue, stack, hashset
thumbnail: /assets/img/posts/generic-collections/main.png
keywords: collections, powershell, list, queue, stack, hashset
usemathjax: false
permalink: /blog/generic-collections/

---

## Introduction

This post will cover some of the generic collections that are available in PowerShell (and .net) that you should be familiar with.

## Overview

Here is a quick list and description of each of the classes that you will read about today:

1. **Queue** - First-in/First-out collection
1. **Stack** - First-in/Last-out collection
1. **List** - The best common PowerShell array there is
1. **Hashset** - A keyed dictionary without the lookup/value portion


## Commands

Each of these come from the ```[System.Collections.Generic]``` library. You can read about everything in that namespace easily on the Microsoft documentation site.

These classes are each coded to a specific type during creation. This means that anything you put into these arrays will get cast to that destination type when inserted. If it cannot be cast, then the insertion will fail and error.

Because these arrays enforce a specific type, they are often pronounced as “of T”. For example, ```[List<T>]``` is spoken “List of T”, meaning, list with a specific type. Similarly, you will learn about ```[Queue<T>]```, ```[Stack<T>]```, etc.

Any type that you have in your PowerShell session can be used as the type when creating these arrays. In this post, you will only read about using the type ```[string]```, but remember that you can put anything for the type, including ```[object]``` or ```[psobject]```.

### Queue

The Queue collection provides an easy interface for adding or removing one item at a time in a normally ordered array. Adding is called via Enqueue() and removing is called via Dequeue(). Sometimes it is easiest to see examples. Go run this yourself and play around:

```powershell
$Queue = [System.Collections.Generic.Queue[string]]@()
$Queue.Enqueue("First")
$Queue.Enqueue("Second")
$Queue.Enqueue("Third")
$Queue
```

You can see that the queue does stay ordered. Now, remove an entry and Peek at what is next up in the queue after your dequeue. Notice that when you dequeue an item, it is returned in the pipeline and removed from the queue.

```powershell
$Queue.Dequeue() # First
$Queue.Peek() # Second
```

Since you only did a “peek”, you didn’t actually remove the next item from the array. Run another dequeue and see that you get “second” again.

```powershell
$Queue.Dequeue() # Second
```

Hopefully that’s all making sense. If you need to clear the queue, you can use the handy method called ```.Clear()```

```powershell
$Queue.Clear()
```

### Stack

The Queue collection provides an easy interface for adding or removing one item at a time in a “most recent” ordered array. Adding is called via ```Push()``` and removing is called via ```Pop()```. If you’ve ever used ```Push-Location``` or ```Pop-Location``` (```pushd, popd```), then you may already be familiar with this first-in/last-out method. Go hit an example to check it out in action:

```powershell
$Stack = [System.Collections.Generic.Stack[string]]@()
$Stack.Push("First")
$Stack
$Stack.Push("Second")
$Stack
$Stack.Push("Third")
$Stack
```

You can see that the most recent item pushed onto the stack is at the top of the array when you display the whole thing. When you pop from the array, it takes that first item off the array and spits it out to you:

```powershell
$Stack.Peek()
$Stack.Pop()
```

The previously-second item in the array is now the first position:

```powershell
$Stack
```

Its good to remember that you can check the size of the stack: ```$Stack.Count```

### List

The generic list will feel quite familiar and is generally considered the best collection to use for operations due to its superior performance. There are other arrays in PowerShell like @() and ```[Collections.ArrayList]```. PowerShell is always evolving! But one of the team’s design goals was not to break existing code where possible. As such, there are these older ways to hold data that remain in PowerShell and work fine despite having a better alternative.

The problem with ```@()``` is that as you add items to it via ```$array += "foo"```, it has to create a copy of the entire array and add in the extra data all into a new array. If you will add somewhere between 10k and 100k+ items to it via ```+=```, it becomes noticibly slow performance. This is because it is an array of “fixed” size. Similarly, you can’t remove items from the array at all.

The problem with ```[Collections.ArrayList]``` is that it has been completely superseded. Here’s what MS says about it:

*We don’t recommend that you use the ArrayList class for new development. Instead, we recommend that you use the generic List class.*

Time to try out using the generic list class ```[List<T>]```

```powershell
$List = [System.Collections.Generic.List[string]]@()
$List.Add("First")
$List.Add("Second")
$List.Add("Third")
$List.Add("Last")
$List
```

Pretty simple so far. Now, remove the first item who equals ‘Second’. Notice that it returns $true, indicating that it found something to remove and successfully removed it.

```powershell
$List.Remove("Second")
```

Try removing it again. Notice that it returns $false because it couldn’t find anything to remove that matched that object.

```powershell
$List.Remove("Second")
```

Its worth being familiar with other methods in the list like ```RemoveAll(), RemoveAt(), Reverse(), and IndexOf()```.

### Hashset

This is a very fun collection to know about! Are you familiar with a a hashtable (a keyed dictionary)? If not, go run this code to explore a hashtable:

```powershell
$ht = @{}
$ht.first = 1
$ht.second = 3
$ht.third = 3
$ht.second = 2
$ht
```

Notice that the hashtable has no apparent ordering and that setting the key “second” multiple times will update any previous instance of that key to the new value (second is 2, not 2 and 3).

Now check out maintaining a keyed list in a hashset. Notice that it returns true or false as you attempt to add each item to the array, indicating whether or not it added the item (such as if the array already includes that item):

```powershell
$Hashset = [System.Collections.Generic.Hashset[string]]@()
$Hashset.Add("first")
$Hashset.Add("second")
$Hashset.Add("second")
$Hashset.Add("third")
```

Though it may appeared ordered on viewing the hashset (and i don’t know that I’ve ever seen it be unordered), I have it on good authority that a hashset is not guarenteed to be ordered.

Because a Hashset is keyed, it means that there can’t be duplicates in it. This is a GREAT collection to use when you want to de-duplicate a list. It can be ***MUCH faster*** than the -Unique parameter from ```Select-Object``` or ```Sort-Object```.

***WARNING: Hashsets are case sensitive. Notice that your Hashset contains “first”, but not “First”***

```powershell
$Hashset.Contains("first") #true
$Hashset.Contains("First") #false
```

## Collection Constructors

Here's a few usefull wrappers to create the collection types I described above.

### Ceating a New [List]

New-GenericList

```powershell

function New-GenericList
{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [string] $InputObject
    )

    $collectionTypeName = "System.Collections.Generic.List[$InputObject]"
    return New-Object $collectionTypeName
}
```


### Ceating a New [Queue]

New-GenericQueue

```powershell
function New-GenericQueue
{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [string] $InputObject
    )

    $collectionTypeName = "System.Collections.Generic.Queue[$InputObject]"
    return New-Object $collectionTypeName
}
```

### Ceating a New [HashSet]

New-GenericHashSet


```powershell
function New-GenericHashSet
{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [string] $InputObject
    )

    $collectionTypeName = "System.Collections.Generic.HashSet[$InputObject]"
    return New-Object $collectionTypeName
}
```

### Ceating a New [Stack]

New-GenericStack

```powershell
function New-GenericStack
{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [string] $InputObject
    )

    $collectionTypeName = "System.Collections.Generic.Stack[$InputObject]"
    return New-Object $collectionTypeName
}
```

### Ceating a New [Dictionary]

New-GenericDictionary

```powershell
function New-GenericDictionary
{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [string] $KeyTypeName,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [string] $ValueTypeName
    )

    $collectionTypeName = "System.Collections.Generic.Dictionary[$KeyTypeName, $ValueTypeName]"
    return New-Object $collectionTypeName
}
```



## Wrapping Up

There you have it, some really nifty patterns to use when the situation calls for it. As usual my priorities when scripting are:

1. Make it work first.
1. Make it work fast enough.
1. Make it clean enough to work on next time.