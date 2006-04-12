# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron


# current nasal version doesn't accept :
# - too many multiplications on 1 line.
# - variable with hyphen.
# - boolean (can only test IF TRUE); replaced by strings.

# IMPORTANT : always uses /consumables/fuel/tank[0]/level-gal_us, because /level-lb seems not synchronized with
# level-gal_us, during the time of a procedure.


# =========
# CONSTANTS
# =========

Constant = {};

Constant.new = func {
   obj = { parents : [Constant],

           TRUE : 1.0,                             # no boolean
           FALSE : 0.0,

           GALUSTOLB : 6.6,                        # 1 US gallon = 6.6 pound

           HOURTOSECOND : 3600.0,
           MINUTETOSECOND : 60.0,
         };

   return obj;
};


# ===========
# FUEL SYSTEM
# ===========

Fuel = {};

Fuel.new = func {
   obj = { parents : [Fuel],
           SPEEDUPSEC : 2,             # refresh rate
           CLIMBFTPMIN : 1200,         # average climb rate
           CLIMBFTPSEC : 0.0,
           MAXSTEPFT : 0.0,
           CONTENT7TO10LB : 4.4        # tanks content
         };

   obj.init();

   return obj;
};

Fuel.init = func {
   me.CLIMBFTPSEC = me.CLIMBFTPMIN / constant.MINUTETOSECOND;
   me.MAXSTEPFT = me.CLIMBFTPSEC * me.SPEEDUPSEC;

   me.presetfuel();
}

# fuel configuration
Fuel.presetfuel = func {
   # default is 0
   fuel = getprop("/sim/presets/fuel");
   if( fuel == nil ) {
       fuel = 0;
   }
   fillings = props.globals.getNode("/sim/presets/tanks").getChildren("filling");
   if( fuel < 0 or fuel >= size(fillings) ) {
       fuel = 0;
   } 
   presets = fillings[fuel].getChildren("tank");
   tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
   for( i=0; i < size(presets); i=i+1 ) {
        child = presets[i].getChild("level-gal_us");
        if( child != nil ) {
            level = child.getValue();
            tanks[i].getChild("level-gal_us").setValue(level);
        }
   } 
}

# control
Fuel.schedule = func {
   me.speedupfuel();
   me.crossfeed();
}

# speed up engine, arguments :
# - engine tank
# - fuel flow of engine
# - outboard tank
# - speed up
Fuel.speedupengine = func {
   enginetank = arg[0];
   flowgph = arg[1];
   outboardtank = arg[2];
   multiplier = arg[3];

   if( flowgph == nil ) {
       flowgph = 0;
   }

   # fuel consumed during the time step
   if( flowgph > 0 ) {
       multiplier = multiplier - 1;
       enginegal = flowgph * multiplier;
       enginegal = enginegal / constant.HOURTOSECOND;
       enginegal = enginegal * me.SPEEDUPSEC;

       tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");

       # center tank first
       tankgal = tanks[4].getValue("level-gal_us");
       if( tankgal > 0 ) {
           if( tankgal > enginegal ) {
               tankgal = tankgal - enginegal;
               enginegal = 0;
           }
           else {
               enginegal = enginegal - tankgal;
               tankgal = 0;
           }
           tanks[4].getChild("level-gal_us").setValue(tankgal);
       } 

       # then outboard tank
       if( outboardtank >= 0 and enginegal > 0 ) {
           tankgal = tanks[outboardtank].getValue("level-gal_us");
           if( tankgal > 0 ) {
               if( tankgal > enginegal ) {
                   tankgal = tankgal - enginegal;
                   enginegal = 0;
               }
               else {
                   enginegal = enginegal - tankgal;
                   tankgal = 0;
               }
               tanks[outboardtank].getChild("level-gal_us").setValue(tankgal);
           }
       } 

       # engine tank at last
       if( enginegal > 0 ) {
           tankgal = tanks[enginetank].getValue("level-gal_us");
           if( tankgal > 0 ) {
               if( tankgal > enginegal ) {
                   tankgal = tankgal - enginegal;
                   enginegal = 0;
               }
               else {
                   enginegal = enginegal - tankgal;
                   tankgal = 0;
               }
               tanks[enginetank].getChild("level-gal_us").setValue(tankgal);
           }
       } 
   }
}

# speed up consumption
Fuel.speedupfuel = func {
   altitudeft = getprop("/position/altitude-ft");
   speedup = getprop("/sim/speed-up");
   if( speedup > 1 ) {
       engines = props.globals.getNode("/engines/").getChildren("engine");
       galphour = engines[0].getValue("fuel-flow-gph");
       me.speedupengine( 0, galphour, -1, speedup );
       galphour = engines[1].getValue("fuel-flow-gph");
       me.speedupengine( 1, galphour, 5, speedup );
       galphour = engines[2].getValue("fuel-flow-gph");
       me.speedupengine( 2, galphour, 6, speedup );
       galphour = engines[3].getValue("fuel-flow-gph");
       me.speedupengine( 3, galphour, -1, speedup );

       # accelerate day time
       node = props.globals.getNode("/sim/time/warp");
       multiplier = speedup - 1;
       offsetsec = me.SPEEDUPSEC * multiplier;
       warp = node.getValue() + offsetsec; 
       node.setValue(warp);

       # safety
       lastft = getprop("/systems/fuel-pump/speed-up-ft");
       if( lastft != nil ) {
           stepft = me.MAXSTEPFT * speedup;
           maxft = lastft + stepft;
           minft = lastft - stepft;

           # too fast
           if( altitudeft > maxft or altitudeft < minft ) {
               setprop("/sim/speed-up",1);
           }
       }
   }

   setprop("/systems/fuel-pump/speed-up-ft",altitudeft);
}

# transfer between 2 tanks, arguments :
# - number of tank destination
# - content of tank destination (lb)
# - number of tank source
# - pumped volume (lb)
Fuel.transfertanks = func {
   tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
   idest = arg[0];
   tankdestlb = tanks[idest].getChild("level-gal_us").getValue() * constant.GALUSTOLB;
   contentdestlb = arg[1];
   maxdestlb = contentdestlb - tankdestlb;
   isour = arg[2];
   tanksourlb = tanks[isour].getChild("level-gal_us").getValue() * constant.GALUSTOLB;
   maxsourlb = tanksourlb - 0;
   pumplb = arg[3];
   # can fill destination
   if( maxdestlb > 0 ) {
       # can with source
       if( maxsourlb > 0 ) {
           if( pumplb <= maxsourlb and pumplb <= maxdestlb ) {
               tanksourlb = tanksourlb - pumplb;
               tankdestlb = tankdestlb + pumplb;
           }
           # destination full
           elsif( pumplb <= maxsourlb and pumplb > maxdestlb ) {
               tanksourlb = tanksourlb - maxdestlb;
               tankdestlb = contentdestlb;
           }
           # source empty
           elsif( pumplb > maxsourlb and pumplb <= maxdestlb ) {
               tanksourlb = 0;
               tankdestlb = tankdestlb + maxsourlb;
           }
           # source empty and destination full
           elsif( pumplb > maxsourlb and pumplb > maxdestlb ) {
               # source empty
               if( maxdestlb > maxsourlb ) {
                   tanksourlb = 0;
                   tankdestlb = tankdestlb + maxsourlb;
               }
               # destination full
               elsif( maxdestlb < maxsourlb ) {
                   tanksourlb = tanksourlb - maxdestlb;
                   tankdestlb = contentdestlb;
               }
               # source empty and destination full
               else {
                  tanksourlb = 0;
                  tankdestlb = contentdestlb;
               }
           }
           # user sees emptying first
           # JBSim only sees US gallons
           tanksourgalus = tanksourlb / constant.GALUSTOLB;
           tanks[isour].getChild("level-gal_us").setValue(tanksourgalus);
           tankdestgalus = tankdestlb / constant.GALUSTOLB;
           tanks[idest].getChild("level-gal_us").setValue(tankdestgalus);
       }
   }
}

# cross feed emulation
Fuel.crossfeed = func {
   nbtanks = 0;
   engines = props.globals.getNode("/controls/fuel").getChildren("engine");
   tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
   crosstanks = props.globals.getNode("/systems/fuel-pump/tanks").getChildren("tank");
   crossengines = props.globals.getNode("/systems/fuel-pump/engines").getChildren("engine");
   for( i=0; i < size(engines); i=i+1 ) {
        if( engines[i].getChild("cross-feed").getValue() ) {
            crossengine = "on";
            # engine tank
            if( tanks[i].getChild("level-gal_us").getValue() > 0.0 ) {
                nbtanks = nbtanks + 1;
                cross = "on";
            } else {
                cross = "";
            }
            crosstanks[i].getChild("cross").setValue(cross);
            # inboard tank
            if( i == 1 or i == 2 ) {
                inboard = 4 + i;
                if( tanks[inboard].getChild("level-gal_us").getValue() > 0.0 ) {
                    nbtanks = nbtanks + 1;
                    cross = "on";
                } else {
                    cross = "";
                }
                crosstanks[inboard].getChild("cross").setValue(cross);
            }
        }
        else {
            crossengine = "";
        }
        crossengines[i].getChild("cross").setValue(crossengine);
   }

   # supplies the virtual cross feed tank of each connected engine
   if( nbtanks > 0 ) {
       # record level of cross feed tanks
       for( i=7; i < size(tanks); i=i+1 ) {
            levellb = tanks[i].getChild("level-gal_us").getValue();
            crosstanks[i].getChild("level-gal_us").setValue(levellb);
       }

       for( i=0; i < 7 ; i=i+1 ) {
            if( crosstanks[i].getChild("cross").getValue() == "on" ) {
                 for( j=0; j < size(crossengines); j=j+1 ) {
                     if( crossengines[j].getChild("cross").getValue() == "on" ) {
                         icross = 7 + j;
                         offsetlb = me.CONTENT7TO10LB - crosstanks[icross].getChild("level-gal_us").getValue();
                         pumplb = offsetlb / nbtanks;
                         me.transfertanks( icross, me.CONTENT7TO10LB, i, pumplb );
                     }
                }
            }
       }
   }
}


# =========
# Autopilot
# =========

Autopilot = {};

Autopilot.new = func {
   obj = { parents : [Autopilot],
           SPEEDUPSEC : 5             # refresh rate
         };
   return obj;
};


# autopilot hold
Autopilot.apexport = func {
    modev = getprop("/autopilot/locks/altitude");
    # if not altitude on
    if( modev != "altitude-hold" ) {
        modeh = getprop("/autopilot/locks/heading");
        if( modev != "pitch-hold" or ( modeh != "dg-heading-hold" and modeh != "true-heading-hold" ) ) {
            modev = "pitch-hold";
            pitchdeg = getprop("/orientation/pitch-deg");
            setprop("/autopilot/settings/target-pitch-deg",pitchdeg);

            modeh = "dg-heading-hold";
            headingdeg = getprop("/orientation/heading-magnetic-deg");
            setprop("/autopilot/settings/heading-bug-deg",headingdeg);
        }
        else {
            modev = "";
            modeh = "";
        }

        setprop("/autopilot/locks/altitude",modev);
        setprop("/autopilot/locks/heading",modeh);
    }
}

# altitude hold
Autopilot.apaltitudeexport = func {
    modeh = getprop("/autopilot/locks/heading");
    # only if autopilot on
    if( modeh == "dg-heading-hold" or modeh == "true-heading-hold" ) {
        modev = getprop("/autopilot/locks/altitude");
        if( modev != "altitude-hold" ) {
            modev = "altitude-hold";
            altitudeft = getprop("/instrumentation/altimeter/indicated-altitude-ft");
            setprop("/autopilot/settings/target-altitude-ft",altitudeft);
        }
        else {
            modev = "pitch-hold";
            pitchdeg = getprop("/orientation/pitch-deg");
            setprop("/autopilot/settings/target-pitch-deg",pitchdeg);
        }

        setprop("/autopilot/locks/altitude",modev);
    }
}

# pitch autopilot :
# - coefficient
Autopilot.pitchexport = func( coef ) {
    altitudemode = getprop("/autopilot/locks/altitude");
    if( altitudemode != nil and altitudemode != "" ) {
        pitchdeg = getprop("/autopilot/settings/target-pitch-deg");
        if( coef >= 0 ) {
            pitchdeg = pitchdeg + 0.15 * coef;
            if( pitchdeg > 12 ) {
                pitchdeg = 12;
            }
        }
        else {
            pitchdeg = pitchdeg + 0.15 * coef;
            if( pitchdeg < -12 ) {
                pitchdeg = -12;
            }
        }
        setprop("/autopilot/settings/target-pitch-deg",pitchdeg);

        result = constant.TRUE;
    }
    else {
        result = constant.FALSE;
    }

    return result;
}

# auto throttle
Autopilot.atexport = func{
   speed = getprop("/autopilot/locks/speed");
   if( speed == "speed-with-throttle-arm" or speed == "speed-with-throttle" ) {
       speed = "";
   }
   else {
       speed = "speed-with-throttle-arm";
   }
   setprop("/autopilot/locks/speed",speed);
}

# autopilot help testing during speed-up
Autopilot.schedule = func {
   heading = getprop("/autopilot/locks/heading");
   speed = getprop("/autopilot/locks/speed");

   # activate speed-up modes
   speedup = getprop("/sim/speed-up");
   if( speedup > 1 ) {
       # keep the target speed
       if( speed == "speed-with-throttle-arm" ) {
           setprop("/autopilot/locks/speed","speed-with-throttle");
       }
       # follows waypoints
       if( heading == "dg-heading-hold" ) {
           waypoints = props.globals.getNode("/autopilot/route-manager").getChildren("wp");
           ident = waypoints[0].getChild("id").getValue();
           if( ident != nil ) {
               if( ident != "" ) {
                   setprop("/autopilot/locks/heading","true-heading-hold");
               }
           }
       }
   }

   # restore default modes
   else {
       if( speed == "speed-with-throttle" ) {
           setprop("/autopilot/locks/speed","speed-with-throttle-arm");
       }
       # keep the current heading
       if( heading == "true-heading-hold" ) {
           altitude = getprop("/autopilot/locks/altitude");
           if( altitude == "pitch-hold" or altitude == "altitude-hold" ) {
               headingdeg = getprop("/orientation/heading-magnetic-deg");
               setprop("/autopilot/settings/heading-bug-deg",headingdeg);
               mode =  "dg-heading-hold";
           }
           # autopilot not activated, that was a new waypoint
           else {
               mode = "";
           }
           setprop("/autopilot/locks/heading",mode);
       }
   }
}


# =====
# Seats
# =====

Seats = {};

Seats.new = func {
   obj = { parents : [Seats],
           lookup : { "engineer" : 0, "radio" : 0, "copilot" : 0, "navigator" : 0, "door" : 0 },
           names : [ "engineer", "radio", "copilot", "navigator", "door" ],
           nb_seats : 5
         };

   obj.init();

   return obj;
};

Seats.init = func {
   theviews = props.globals.getNode("/sim").getChildren("view");
   last = size(theviews);

   # retrieve the index as created by FG
   for( i = 0; i < last; i=i+1 ) {
        name = theviews[i].getChild("name").getValue();
        if( name == "Engineer View" ) {
            me.lookup["engineer"] = i;
        }
        elsif( name == "Radio View" ) {
            me.lookup["radio"] = i;
        }
        elsif( name == "Copilot View" ) {
            me.lookup["copilot"] = i;
        }
        elsif( name == "Navigator View" ) {
            me.lookup["navigator"] = i;
        }
        elsif( name == "Door View" ) {
            me.lookup["door"] = i;
        }
   }
}

Seats.viewexport = func( name ) {
   theseats = props.globals.getNode("/sim/current-view/seat");
   if( name != "captain" ) {

       # swap to view
       if( !theseats.getChild(name).getValue() ) {
           index = me.lookup[name];
           setprop("/sim/current-view/view-number", index);
           theseats.getChild(name).setValue(constant.TRUE);
           theseats.getChild("captain").setValue(constant.FALSE);
       }

       # return to captain view
       else {
           setprop("/sim/current-view/view-number", 0);
           theseats.getChild(name).setValue(constant.FALSE);
           theseats.getChild("captain").setValue(constant.TRUE);
       }

       # disable all other views
       for( i = 0; i < me.nb_seats; i=i+1 ) {
            if( name != me.names[i] ) {
                theseats.getChild(me.names[i]).setValue(constant.FALSE);
            }
       }
   }

   # captain view
   else {
       setprop("/sim/current-view/view-number",0);
       theseats.getChild("captain").setValue(constant.TRUE);

        # disable all other views
        for( i = 0; i < me.nb_seats; i=i+1 ) {
             theseats.getChild(me.names[i]).setValue(constant.FALSE);
        }
   }
}

Seats.scrollexport = func{
   # number of views = 11
   nbviews = getprop("/sim/number-views");

   # by default, returns to captain view
   targetview = nbviews;

   # if specific view, step once more to ignore captain view 
   theseats = props.globals.getNode("/sim/current-view/seat");
   for( i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( theseats.getChild(name).getValue() ) {
            targetview = me.lookup[name];
            break;
        }
   }

   # number of default views (preferences.xml) = 6
   nbdefaultviews = nbviews - me.nb_seats;

   # last default view (preferences.xml) = 5
   lastview = nbdefaultviews - 1;

   # moves to seat
   if( getprop("/sim/current-view/view-number") == lastview ) {
       step = targetview - nbdefaultviews;
       view.stepView(step);
       view.stepView(1);
   }

   # returns to captain
   elsif( getprop("/sim/current-view/view-number") == targetview ) {
       step = nbviews - targetview;
       view.stepView(step);
       view.stepView(1);
   }

   # default
   else {
       view.stepView(1);
   }
}

Seats.scrollreverseexport = func{
   # number of views = 11
   nbviews = getprop("/sim/number-views");

   # by default, returns to captain view
   targetview = 0;

   # if specific view, step once more to ignore captain view 
   theseats = props.globals.getNode("/sim/current-view/seat");
   for( i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( theseats.getChild(name).getValue() ) {
            targetview = me.lookup[name];
            break;
        }
   }

   # number of default views (preferences.xml) = 6
   nbdefaultviews = nbviews - me.nb_seats;

   # last view = 10
   lastview = nbviews - 1;

   # moves to seat
   if( getprop("/sim/current-view/view-number") == 1 ) {
       # to 0
       view.stepView(-1);
       # to last
       view.stepView(-1);
       step = targetview - lastview;
       view.stepView(step);
    }

   # returns to captain
    elsif( getprop("/sim/current-view/view-number") == targetview ) {
        step = nbdefaultviews - targetview;
        view.stepView(step);
        view.stepView(-1);
    }

    # default
    else {
        view.stepView(-1);
    }
}


# =====
# Doors
# =====

Doors = {};

Doors.new = func {
   obj = { parents : [Doors],
           crew : aircraft.door.new("instrumentation/doors/crew", 8.0),
           passenger : aircraft.door.new("instrumentation/doors/passenger", 10.0)
         };
   return obj;
};

Doors.crewexport = func {
   me.crew.toggle();
}

Doors.passengerexport = func {
   me.passenger.toggle();
}


# ==============
# Initialization
# ==============

# 2 s cron
sec2cron = func {
   fuelsystem.schedule();

   # schedule the next call
   settimer(sec2cron,fuelsystem.SPEEDUPSEC);
}

# 5 s cron
sec5cron = func {
   autopilotsystem.schedule();

   # schedule the next call
   settimer(sec5cron,autopilotsystem.SPEEDUPSEC);
}

init = func {
   # schedule the 1st call
   sec2cron();
   sec5cron();
}

# objects must be here, otherwise local to init()
constant = Constant.new();
fuelsystem = Fuel.new();
doorsystem = Doors.new();
seatsystem = Seats.new();
autopilotsystem = Autopilot.new();

init();
