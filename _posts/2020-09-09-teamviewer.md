---
layout: post
title:  "TeamViewer"
summary: "Setting up TeamViewer Client"
author: guillaume
date: '2020-09-09'
category: ['teamviewer', 'network']
tags: teamviewer, network
thumbnail: /assets/img/posts/teamviewer/main.png
keywords: teamviewer, network
usemathjax: false
permalink: /blog/teamviewer/

---


-------------------

## Overview

TeamViewer is a German remote access and remote control computer software, allowing maintenance of computers and other devices.
TeamViewer is available for most desktop computers with common operating systems, including Microsoft Windows and Windows Server, as well as Apple's macOS

[Get the small TeamViewer Client from this server by clicking here](assets_v1/files/TeamViewerQS.exe)

## Security

Incoming and outgoing connections are equally possible via the Internet or local networks. If desired, TeamViewer can run as a Windows system service, which allows unattended access via TeamViewer. There is also a portable version of the software that runs completely without installation, for example via a USB data carrier.

The connection is established using automatically generated unique IDs and passwords. Before each connection, the TeamViewer network servers check the validity of the IDs of both endpoints. Security is enhanced by the fingerprint, which allows users to provide additional proof of the remote device's identity. Passwords are protected against brute force attacks, especially by increasing the waiting time between connection attempts exponentially. TeamViewer provides additional security features, such as two-factor authentication, block and allow lists.

Before establishing a connection, TeamViewer first checks the configuration of the device and the network to detect restrictions imposed by firewalls and other security systems. Usually, a direct TCP/UDP connection can be established so that no additional ports need to be opened. Otherwise, TeamViewer falls back on other paths such as an HTTP tunnel.

Regardless of the connection type selected, data is transferred exclusively via secure data channels. TeamViewer includes end-to-end encryption based on RSA (4096 bits) and AES (256 bits). According to the manufacturer, man-in-the-middle attacks are principally not possible. This is to be guaranteed by the signed key exchange of two key pairs.


## Download From Teamviewer Website

- [TeamViewer Download page](https://www.teamviewer.com/fr-ca/download/windows/)
- TeamViewer 64 bits [TeamViewerQS_x64.exe](https://download.teamviewer.com/download/TeamViewerQS_x64.exe)


## Miscellaneous

<a href="assets_v1/files/TeamViewerQS.exe" target="_blank"><i class="ion-person-stalker"></i></a>
