---
layout: post
title:  "BMW 335i Tank Leakage Diagnostic Module (DM-TL) Malfunction"
summary: "Tank Leakage Diagnostic Module (DM-TL) - Malfunction, pump current too high, Fuel level / Fuel consumption - correlation error"
author: guillaume
date: '2023-10-08'
category: ['bmw','n54','dmtl', 'fuel', 'correlation error']
tags: bmw, ecu, n54, dmtl, fuel
thumbnail: /assets/img/posts/bmw/dmtl.png
keywords: bmw, ecu, n54, correlation, dmtl
usemathjax: false
permalink: /blog/bmw-dmtl-error/

---

<br>

## Tank Leakage Diagnostic Module (DM-TL) - Malfunction


| **Num**           |  **Error ID**             | **Title**                     | Frequency          | **Code**     |   **Description**                                                    |
|:-----------------:|:-------------------------:|:-----------------------------:|:------------------:|:------------:|:--------------------------------------------------------------------:|
| .  Error: 1/3   . | .   No.: 10786 0x2A22   . | .  Tank level, correlation  . | .  frequency: 1  . | .   P144B  . | .  Fuel level / Fuel consumption - correlation error               . |
| .  Error: 2/3   . | .   No.: 11068 0x2B3C   . | .  DMTL, system error       . | .  frequency: 1  . | .   P1434  . | .  Tank Leakage Diagnostic Module (DM-TL) - Malfunction            . |
| .  Error: 3/3   . | .   No.: 11066 0x2B3A   . | .  DMTL, system error       . | .  frequency: 5  . | .   P1449  . | .  Tank leakage diagnostic module (DM-TL) - pump current too high  . |

<br>
<br>

### Details

For those speaking german, here's a link to the original scanner output [text file](https://arsscriptum.github.io/files/bmw/errors.txt).


That fault code refers to the fuel tank evaporative control system, which includes the carbon canister, plumbing for condensing fuel vapors, the purge solenoid valve, and the leak detection unit [DMTL] which pressurizes the fuel tank and evaporative system to monitor system leaks. The DMTL is mounted directly to the activated carbon canister, which is located underneath the vehicle.

I have found those solutions:

1. Replace leak diagnostic pump (Bosch) BavAuto.com part # 0 261 222 018
2. New blue gas cap for safe measure # 16 11 6 756 772.


----------------------------------

