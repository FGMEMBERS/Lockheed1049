Lockheed 1049 real data
=======================
Weight : max takeoff 120000 lb, max landing 98500 lb, maximum without fuel 93500 lb (A).

Vne (never exceed)           : 293 kt until 11000 ft; then - 11 kt / 2000 ft (A).
Vno (normal operation)       : 260 kt until 11000 ft, then - 9 kt / 2000 ft (A).
Vf (takeoff flaps 60%)       : 184 kt (A).
Va (maneuvring)              : 180 kt (A).
Vlo (landing gear operation) : 165 kt (A).
Vle (landing gear extension) : 165 kt (A).
Vf (approach flaps 66%)      : 161 kt (A).
Vf (80%)                     : 153 kt (A).
Vf (landing flaps 100%)      : 148 kt (A).

Engine limits : - takeoff (2.75 minutes) : sea level,   54.5 inhg 2900 rpm;
                                           at 4500 ft,  52.5 inhg 2900 rpm (A).
                - maximum continuous :     sea level,   48.0 inhg 2600 rpm;
                                           at 5300 ft,  46.0 inhg 2600 rpm;
                                           at 10800 ft, 47.5 inhg 2600 rpm;
                                           at 16000 ft, 46.0 inhg 2600 rpm (A).


Climb rate : 1125 ft/min (F).
Ceiling : 25000 ft (A).
Range (max payload) : 1049 : 1890 NM (E).


Comparison with other 1049s
===========================
Cruise  : - 6000 m [19700 ft] (F).
Ceiling : - 25000 ft (B)(C).
          - 23200 ft (D).
          - 8500 m [27900 ft] (F).
Range (max payload) :
          - 1049C : 2510 NM (E).
Range (max fuel) :
          - 1049C : 4160 NM (B).
          - 3450 NM, 16.5 h maximum, 24790 l (C). 
          - 3500 NM, 14 h without reserve, 6550 US gal (D).
          - 1049C : 4760 NM (E).

The range of 1049 should be 3580 NM = 4760 x (1890 / 2510).


Lockheed 1049 ops
=================
- take-off : - flaps 1/4, 2900 RPM.
             - rotation 130 kt (full load), 120 kt (landing load) :
               raise slowly the nose until the gear lefts the ground (a little nose heavy).
             - retract gear below 165 kt.
             - retract flaps below 184 kt.
- climb    : - always above 180 kt (drag).
             - reduce throttle to 48 inhg, then reduce pitch to 2600 RPM (engine temperature).
             - reduce pitch to the lowest RPM (if not enough, reduce throttle),
             - decrease mixture (highest torque (G) and EGT) with altitude, otherwise engine stops.
             - above 12500 ft, high blower.
- cruise   : - 220 kt at 20000 ft, 197 kt at 25000 ft (2600 RPM).
             - min mixture, min pitch (with stable RPM).
- descent  : - below 12500 ft, low blower.
- approach : - 10 NM at 1500 ft, 2600 RPM.
             - flaps 1/4 below 184 kt.
             - gear below 165 kt.
             - maintain 130 kt.
- landing :  - flaps 1/2 below 161 kt.
             - flaps 3/4 below 153 kt, full flaps below 148 kt.
             - maintain 115 kt (landing load), 110 kt (empty load). 
             - touch down 110 kt (landing load), 105 kt (empty load).


Installation
============
A mouse with 3rd (middle) button, or its emulation (left + right button), is required.

Fuel load
---------
- default is maximum landing weight, 98500 lb.
- for alternate load, press "= f" (saved on exit in aircraft-data).

Sounds
------
See Sounds/Lockheed1049-mats-sound.xml to install Constellation sounds (recommended).

Known compatibility
-------------------
3.6.0 RC : minimum version.


Keyboard
========

Views
-----
- "ctrl-E"       : "E"ngineer view.
- "ctrl-K"       : Observer view (floating).
- "ctrl-L"       : Observer 2 view (floating).
- "ctrl-N"       : "N"avigator view.
- "ctrl-O"       : radi"O" view.
- "shift-ctrl-V" : restore view pitch.
- "shift-ctrl-X" : restore floating view.
- "ctrl-Y"       : Copilot view.

Virtual crew
------------
- "ctrl-Q"       : virtual crew.

Unchanged behaviour
-------------------
- "x / X"        : zooms in the small fonts.
                   Reset with "ctrl-X".

Same behaviour
--------------
- "S"            : "S"waps between Captain and Engineer 2D panels.
- "F12"          : radio frequencies.
 
Improved behaviour
------------------
- "a / A"        : speeds up BOTH speed and time. Until X 10.
                   Automatically resets to 1, when above 2000 ft/min.
- "ctrl-A"       : hold "A"ltitude.
- "ctrl-H"       : toggle autopilot (hold both "H"eading and pitch).
- "ctrl-P"       : toggle autopilot (hold both heading and "P"itch).
- "ctrl-S"       : autothrottle (virtual copilot).
- "left /        : autopilot heading (knob).
   right"
- "up /          : increases / decreases pitch hold.
   down"
- "page up /     : increases / decreases copilot speed.
   page down"

Alternate behaviour
-------------------
- "ctrl-B"       : propeller reverse used as "B"rake (not yet implemented by FDM).
- "="            : menu.
- "left /        : move floating view in width.
   right"
- "up /          : move floating view in length.
   down"
- "page up /     : move floating view in height.
   page down"

Additional behaviour
--------------------
- "ctrl-F"       : surface control boost.
- "f"            : "f"ull cockpit (all instruments).
- "q"            : "q"uit speed up.
- "ctrl up /     : increases / decreases pitch hold (slow).
   ctrl down"
- "ctrl up /     : move floating view in length (fast).
   ctrl down"


Mouse
=====

ADF
---
To update the frequency of ADF 2 :
- press "XFR" on the overhead.
- press "ctrl-R" to call the radio menu. 

When out of range, ADF needle parks at 90 degrees.

Cross-feed
----------
To feed an engine with the tanks of another engine, set fully the lever at the bottom. 

VOR
---
When out of range, VOR needle is steady (use light of deviation indicator).


Virtual crew
============
Copilot
-------
- can hold throttle and follow waypoints.
- is never the pilot in command.

Engineer
--------
- swaps blower.


Consumption
===========
Cruise speed 2300 RPM (full throttle, min pitch, min mixture), for 1 engine :
- full load, 220 kt 130 gallons/h at 20000 ft, 2450 RPM (J = 1.89).
- empty load,197 kt 150 gallons/h at 25000 ft, 2450 RPM (J = 1.56).

As the real fuel is 1 US gal = 6 lb (A), multiply by 6.6 / 6 to compare with the real consumption.

Example
-------
KJFK - EHAM , 3200 NM (via CYQM Moncton, CYQX Gander, EINN Shannon) :
- at 20h50 zulu (afternoon), takeoff at full load (5954 gallons), heading 85 deg.
- tail wind 270 deg 20 kt.
- cruise starts at 20000 ft, +1000 ft every 2h.
- after 10h15, lands in the morning with 400 gallons or 0h45 (135 gallons/h).

EHAM - KJFK , 3200 NM (via EINN Shannon, CYQX Gander, CYQM Moncton) :
- at 6h15 zulu (morning), takeoff at full load (5954 gallons), heading 285 deg.
- head wind 270 deg 20 kt.
- cruise starts at 20000 ft, +1000 ft every 2h.
- after 10h, cruises CYQM with 670 gallons at 515 NM from KJFK.
- after 12h, run out of fuel at 0h30 of KJFK.


JSBSim
======
- real propeller diameter (15.0 ft).
- real gear ratio 16:7.


TO DO
=====
- 3D instruments.
- scale instruments on engineer panel.

TO DO FDM
---------
- reversed propeller : ctrl-B only animates the lights and levers.


Known problems
==============
- data are not saved on reinit.

Known problems autopilot
------------------------
- toggle waypoint following (virtual copilot), only AFTER activation of route, or use "= a".

Known problems 3.4.0 autopilot
------------------------------
- on engagement, true heading mode banks into the opposite direction.

Known problems FDM
------------------
- cross feed emulation until speed-up X 3, when empty tank.


Secondary problems
==================

Secondary problems FDM
----------------------
- cylinder head temperature too high.


References
==========
(A) http://www.airweb.faa.gov/Regulatory_and_Guidance_Library/rgMakeModel.nsf/MainFrame?OpenFrameSet :
    (FAA certificate, 6a5 - 14 may 1952).

(B) http://cip.physik.uni-wuerzburg.de/~pschirus/aviation/flugzeuge/constellation.phtml :

(C) http://www.hars.com.au/fleet/constellation/facts.html :
    (VH-EAG : 1049F, C-121C).

(D) http://www.superconstellation.org/ :
    (N73544 : 1049F, C-121C).

(E) http://www.airliners.net/discussions/general_aviation/read.main/1738757/4/ :

(F) http://aviatechno.free.fr/constellation/ :

(G) http://www.factorypipe.com/t_brake.php :
    Power is proportional to RPM and BMEP.


1st November 2015.
