# My Personal Website

This is my personal website

## How to post

1. Write a markdown document in ```.\_posts\```. Or use the [New-Post.ps1](.\scripts\New-Post.ps1) script
2. Make sure the date is correct
3. if a new category is added run the [New-Category.ps1](.\scripts\New-Category.ps1) script
4. build, set version and commit using the [Make.ps1](.\Make.ps1) script

## How to build

```
  . ./Make.ps1 -Push
```

## How to add a video

Use the ```control``` tag to set autoplay, etc

```
	<video class="car_vid" controls autoplay loop muted>
	  <source src="https://arsscriptum.github.io/files/bmw/damper.mp4" type="video/mp4">
	  This browser does not display the video tag.
	</video>
```

## Versioning Details

Automatic