---
layout: post
title:  "BMW ECU HACKING"
summary: "my experience in tuning / fixing error code on my BMW"
author: guillaume
date: '2022-12-04'
category: ['bmw','n54']
tags: bmw, ecu, n54
thumbnail: /assets/img/posts/bmw/1.png
keywords: bmw, ecu, n54, faults
usemathjax: false
permalink: /blog/bmw-n54-ecu-coding/

---


#### Electronic Tuning - My Experience

This page is my experience in tuning / fixing error code on my BMW. I do this with the help of Reddit user [domrosiak123](https://www.reddit.com/user/domrosiak123)


#### MY HARDWARE 

[USB K+DCAN Cable](https://www.ebay.ca/itm/144466892972?mkcid=16&mkevt=1&mkrid=711-127632-2357-0&ssspo=owcbbmgksus&sssrc=2047675&ssuid=&widget_ver=artemis&media=COPY) with Switch / Button For Use With BMWs From 2007 – 2022
his cable allows full diagnosis of all BMWs manufactured from 2007 – 2022. It works with the following


- INPA
- ISTA+, / D, / P
- DIS V44 / V57
- Progman SSS V32
- NCS Expert
- WinKFP
- NavCoder




![cable](https://arsscriptum.github.io/assets/img/posts/bmw/cable1.png)

#### MY GOALS 

Those are my main goals, the reason I bought the cable:


- diagnostic of [Limp Mode](assets/img/posts/bmw/limp.png)
- Diagnostic : AIR BAG / SEAT BELT Error Code Reset



If I succeeded with my main goals, I will try this:

- Wish list (optional) : Remove the chimes bells when my seat belt is not fastened
- Wish list (optional) : Performance Upgrade ?




#### SOFTWARE 

I have downloaded the [Standard Tools from BimmerGeeks](https://www.bimmergeeks.net/downloads)

I have archived the tools on [Github](https://github.com/arsscriptum/BimmerGeeks.StandardTools)
I still have questions regarding this, do I need more software ? hat is the differencec between  ***ISTA*** and ***Inpa*** ?


#### HOW TO USE - IMPORTANT NOTES 

Before any coding, from what I gathered, I need to do the following:

1) Plug in a battery charger to the battery, to avoid poweroff while coding
2) Fasten the driver seat seatbelt to avoid going in sleep mode





#### INSTALL INSTRUCTIONS IN BIMMERGEEKS STANDARD TOOLS 

1. Run St212.exe using all default settings except the 4 checkbox options in the "select additional task" window regarding "backup and restore" and "create desktop/quick launch icons" . 
(If using Windows 10, run in st212.exe in "Compatibility Mode" for Windows 7)

2. After install completes, select "No" to restarting PC.

3. Navigate to your C:\ drive and delete the folders labeled "EC-APPS, EDIABAS & NCSEXPER"

4. Replace those folders with the "EC-APPS, EDIABAS & NCSEXPER" from this download by copying them to the C:\ drive.

5. Copy the 3 files inside the OCX folder and paste them in the C:\Windows\Syswow64 folder. If you do not have this folder you are a 32-bit system meaning you need to paste them in C:\Windows\system32 instead.

6. Open Command Prompt as administrator & enter the following commands. Please note if your 32bit system, start on the 2nd line: If you have issues getting the commands to succeed, make sure your running command prompt as administrator.

cd c:\windows\syswow64
(Press Enter)
regsvr32 mscomctl.ocx
(Press Enter & wait for "Registration Succeeded" message)
regsvr32 msflxgrd.ocx
(Press Enter & wait for "Registration Succeeded" message)
regsvr32 comdlg32.ocx
(Press Enter & wait for "Registration Succeeded" message)

7. Place the "BMW Tools" folder(BMW icon) on your desktop. Shortcuts to all the software are inside.

8. Make sure your cable is set to COM-1 with a Latency Timer as 1 in device manager.

9. Reboot Computer.

10. Installation is complete.

![faults](https://arsscriptum.github.io/assets/img/posts/bmw/bmwfaults.png)