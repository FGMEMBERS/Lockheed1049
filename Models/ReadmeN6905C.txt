The real aircraft
=================
N6905C "Star of the Rhone" (A) was a Lockheed 1049, the first Super Constellation,
underpowered at 2700 HP (like the 1049A military). Sold to Eastern and TWA (B,C),
it could fly non-stop Los Angeles to New York (max fuel).

The turbo-compound engine (3250 HP with boost stage) appears with the 1049B (military C121),
and 1049C (civilian) :
- with favourable westerly winds, the 1049C could cross the Atlantic from the west (KLM,
New-York - Amsterdam, 15 August 1953 (D)).
- with the 1049C, TWA entered regular service between New York and Los Angeles
(max payload, 19 October 1953 (E)).
- with the 1049G, slightly longer, and with optional fuel tanks at wing tip,
TWA entered transatlantic service.
Only the DC-7 and 1649 (Starliner) could fly non-stop the Atlantic by all weather.


N6905C, as serial number 4019 (B), is a model 1049-54-80 (F) (domestic or international
configuration), recognizable by the holes of passenger windows. 
The 1049 also has a distinctive round nose (A)(G), like its predecessor 749,
while a conic nose (weather radar, like the military 1049A) appears among its successors (H),
announcing the 1649.

1049-54-80 (I) having the same fuel quantity than the 1049C (thanks to optional center tank 5),
should have the same at the edge range (KJFK - EHAM), though never used in practice;
the 1890 NM range at max payload (J) would be without tank 5 (not enough for KJFK - KLAX).


Model
=====
The following proportions are respected (1 Blender unit = 1 m) :
- overall length and width.
- in length : wing 3/6, rudder 5/6.
- in height : fuselage maximum / gear clearance 11.6/7.
- relative length : cockpit window / cockpit 7/25, cockpit / till propeller cone 25/80.
- in fuselage height : passenger window 13/27 (bottom) to 17/27 (top),
                       cockpit window 15/27 (bottom) to 20/27 (top).     
- in propeller diameter : engine 1/3.

The door animation controls the 3D cockpit fitting.

Inspired by N6937C (H) :
- navigator station.


Transparency
------------
Propeller discs must be the last of the file :
- all other objects belong to a fuselage or cockpit group at the export.
- for windows transparency, cockpit is the parent of fuselage.
- for selection during design, cockpit and fuselage are in separate layers
  (one cannot use a group to isolate the cockpit).


VRP
---
The model is aligned vertically along the nose axis, but is still centered horizontally
on the center of gravity :
- that is more handy with the Blender grid. 
- the alignment of VRP to the nose tip is finished by XML (horizontal offset).


Texturing
---------
Colours inspired by N6937C (H) :
- blade tips (red and white).
- cockpit (green, black, beige and metallic).
- seat (metallic, grey and beige).
- yoke (black and blue).
- levers (metallic, red and yellow).

The flag on the right side is reversed (A).

The double red line, the grey ellipse below the fuselage (except the rounded ends),
are delimited by the mesh.

Wings :
- map the right wing.
- reverse scale to the left wing (inversed normals), and map "TWA" above it.
- map "TWA" below the right wing.

The cockpit texture without alpha makes the 2D instruments visible on a panel;
the other texture with alpha is for clipping.

The black rotative switches are visible only if the cockpit black is lighter.

Cockpit objects have a Blender material, to improve the solid view :
swap back to the default white, when a clear texture is lost.


TO DO
=====
- gear compression.
- smoke at engine start.
- radio and navigator seats.
- release the metapost files (panel textures).


Known problems
==============
- front gear inner struts crosses the fuselage.
- the livery is difficult to repaint (not a skin).
- passenger door too thick ?


References
==========
(A) http://www.airliners.net/open.file/099490/L/ :
    L1049, Star of the Rhone, Los Angeles, 1957.

(B) http://www.geocities.com/~aeromoe/fleets/tw.html :
    TWA.

(C) http://www.geocities.com/~aeromoe/fleets/calhaw.html :
    sold to California Hawaiian.

(D) http://www.berlin-spotter.de/airlines/klm.htm :

(E) http://www.strijdbewijs.nl/birds/constellation/connie.htm :

(F) http://www.aerotransport.org/php/go.php?q=regn+N6905C :
    model L1049-54-80.

(G) http://www.airliners.net/open.file/099489/L/ :
    L1049, Star of Sicily, Los Angeles, 1957.

(H) http://www.conniesurvivors.com/N6937C.htm :
    L1049H.

(I) http://www.airweb.faa.gov/Regulatory_and_Guidance_Library/rgMakeModel.nsf/MainFrame?OpenFrameSet :
    (FAA certificate, 6a5 - 14 may 1952).

(J) http://www.airliners.net/discussions/general_aviation/read.main/1738757/4/ :

    http://www.airliners.net/photo/Breitling-(Super-Constellation/Lockheed-C-121C-Super/0568924/L/ :
    overhead panel.

    http://www.eflightmanuals.com/ :
    Lockheed Flight manual.


Credits
-------
Metapost template by M. Franz.

http://www.usflag.org/ : the 49 stars flag (1957 livery).


Made with Blender 2.48a.


31 January 2009.
