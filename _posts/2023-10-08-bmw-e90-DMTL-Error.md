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

<center>
<table table border="2" bgcolor="#ca6521"><thead><tr align="center"><th><strong>Num</strong></th><th><strong>Error ID</strong></th><th><strong>Title</strong></th><th>Frequency</th><th><strong>Code</strong></th><th><strong>Description</strong></th></tr></thead><tbody><tr><td>Error: 1/3</td><td>No.: 10786 0x2A22</td><td>Tank level, correlation</td><td>frequency: 1</td><td>P144B</td><td>Fuel level / Fuel consumption - correlation error</td></tr><tr><td>Error: 2/3</td><td>No.: 11068 0x2B3C</td><td>DMTL, system error</td><td>frequency: 1</td><td>P1434</td><td>Tank Leakage Diagnostic Module (DM-TL) - Malfunction</td></tr><tr><td>Error: 3/3</td><td>No.: 11066 0x2B3A</td><td>DMTL, system error</td><td>frequency: 5</td><td>P1449</td><td>Tank leakage diagnostic module (DM-TL) - pump current too high</td></tr></tbody></table>

<!--<img src="https://arsscriptum.github.io/files/bmw/errors.png" alt="table" />-->
</center>
<br>


<br>
<br>

### Details

For those speaking german, here's a link to the original scanner output [text file](https://arsscriptum.github.io/files/bmw/errors.txt).


That fault code refers to the fuel tank evaporative control system, which includes the carbon canister, plumbing for condensing fuel vapors, the purge solenoid valve, and the leak detection unit [DMTL] which pressurizes the fuel tank and evaporative system to monitor system leaks. The DMTL is mounted directly to the activated carbon canister, which is located underneath the vehicle.

I have found those solutions:

1. Replace leak diagnostic pump (Bosch) BavAuto.com part # 0 261 222 018
2. New blue gas cap for safe measure # 16 11 6 756 772.


----------------------------------

