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


Ceiling : 25000 ft (A).
Range (max payload) : 1049 : 1890 NM (E).


Comparison with other 1049s
===========================
Cruise  : 6000 m [19700 ft] (F).
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
             - rotation 125 kt (full load), 115 kt (empty load) : raise slowly the nose until the gear lefts the ground.
             - retract gear below 165 kt.
             - retract flaps below 184 kt.
- climb    : - 48 inhg, below 2600 RPM.
             - min mixture, min pitch (with stable RPM).
- cruise   : - 220 kt at 20000 ft, 197 kt at 25000 ft (2600 RPM).
             - min mixture, min pitch (with stable RPM).
- descent  : max pitch.
- approach : - max pitch, level to reduce speed, then flaps 1/4 below 184 kt.
             - gear below 165 kt.
             - flaps 1/2 below 161 kt.
             - flaps 3/4 below 153 kt.
             - full flaps below 148 kt.
             - maintain 125 kt (full load). 
- landing  : 110 kt (full load), 100 kt (empty load).


Customizing
===========
Default is maximum landing weight, 98500 lb.
For maximum takeoff weight, 120000 lb, set /sim/presets/fuel to 1.
For other configurations, see Lockheed1049-fuel.xml.

Sounds
------
See Lockheed1049-mats-sound.xml to install Constellation sounds (recommended).


Keyboard
========
- "e / E" : increases / decreases propeller pitch.
- "q"     : resets speed up to 1.

Unchanged behaviour
-------------------
- "left / right" : turns the heading hold.

Same behaviour
--------------
- "s" swaps between Captain and Engineer 2D panels.
 
Improved behaviour
------------------
When speed-up, autothrottle toggles automatically, and heading hold swaps to waypoint hold, if any.

- "ctrl-A" : hold altitude.
- "ctrl-H" : toggle autopilot (hold heading and pitch).
- "ctrl-P" : toggle autopilot (hold heading and pitch).
- "ctrl-S" : toggle autothrottle (speed-up only).
- "up / down"  : increases / decreases (fast) pitch hold.
- "home / end" : increases / decreases (slow) pitch hold.
- "a / A"  : speeds up BOTH speed and time : external view until X 20.
  Automatically resets to 1, when above 2000 ft/min.

ADF
---
To update the frequency of ADF 2 :
- press "swap" at the bottom of the pedestal.
- press "ctrl-R" to call the radio menu. 

Cross-feed
----------
To feed an engine with the tanks of another engine, set fully the lever at the bottom. 


Consumption
===========
Cruise speed 2300 RPM (full throttle, min pitch, min mixture), for 1 engine :
- full load, 220 kt 130 gallons/h at 20000 ft, 2450 RPM (J = 1.89).
- empty load,197 kt 150 gallons/h at 25000 ft, 2450 RPM (J = 1.56).

As the real fuel is 1 US gal = 6 lb (A), multiply by 6.6 / 6 to compare with the real consumption.

All with lateral wind.
Min mixture : before engine cutoff.
Min pitch : before influence on RPM.

Example
-------
KJFK - EHAM , 3200 NM (via CYQM Moncton, CYQX Gander, EINN Shannon) :
- at 20h50 zulu (afternoon), takeoff at full load (5954 gallons), heading 85 deg.
- tail wind 270 deg 20 kt.
- cruise starts at 20000 ft, +1000 ft every 2h.
- after 10h45, lands in the morning with 310 gallons or 0h30 (131 gallons/h).

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
- 3D cockpit.

TO DO JSBSim
-------------
- reversed propeller.
- tank selection.


Known problems
==============

Known problems JSBSim
---------------------
- cross feed emulation until speed-up X 3, when empty tank.
- fakes the displacement to get the real range.
- at rest, idle engine (700 RPM) may yet stop by very low pressure (altimeter 29.49 inhg).

Known problems 2D instrument 
----------------------------
- twinkling of deviation indicator.

Known problems sound
--------------------
- exception through OpenAL errors (low hardware ?) means too many sounds : remove for example engine start/shutdown.


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

(F) http://aviatechno.free.fr/constellation/constellation.php :


12 November 2005.
