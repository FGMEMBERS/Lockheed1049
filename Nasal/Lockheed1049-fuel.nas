# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# IMPORTANT :
# always uses /consumables/fuel/tank[0]/level-gal_us, because /level-lbs seems not synchronized
# with level-gal_us, during the time of a procedure.


# ===========
# FUEL SYSTEM
# ===========

Fuel = {};

Fuel.new = func {
   var obj = { parents : [Fuel],

               tanksystem : Tanks.new(),

               crosstanks : nil,
               crossengines : nil,
               engines : nil,
               sysengines : nil,
               tanks : nil,

               SPEEDUPSEC : 2,             # refresh rate

               PRESSURELOW : 0.5,
         };

   obj.init();

   return obj;
};

Fuel.init = func {
   me.crosstanks = props.globals.getNode("/systems/fuel-pump/tanks").getChildren("tank");
   me.crossengines = props.globals.getNode("/systems/fuel-pump/engines").getChildren("engine");
   me.engines = props.globals.getNode("/controls/fuel").getChildren("engine");
   me.sysengines = props.globals.getNode("/systems/engines").getChildren("engine");
   me.tanks = props.globals.getNode("/controls/fuel").getChildren("tank");

   me.tanksystem.presetfuel();
}

Fuel.menuexport = func {
   me.tanksystem.menu();
}

Fuel.schedule = func {
   # fuel pressure emulation
   me.fuelpressure();

   # cross feed emulation
   me.crossfeed();

   me.red_fuel();
}

Fuel.fuelpressure = func {
   var nbtanks = 0;
   var inboard = 0;
   var icross = 0;
   var itank = 0;

   # record level of cross feed tanks
   me.crosslevel();

   # emulation of fuel pressure
   for( var i=0; i < constantaero.NBENGINES ; i=i+1 ) {
        if( !me.engines[i].getChild("firewall").getValue() ) {
            # supplies the virtual cross feed tank by its engine tank
            icross = constantaero.NBTANKS + i;

            nbtanks = 1;

            # inboard tank
            if( constantaero.isInboardEngine( i ) ) {
                nbtanks = 2;
            }

            for( var j=0; j < nbtanks; j=j+1 ) {
                 # outboard tank
                 if( j > 0 ) {
                     itank = constantaero.outboardTank( i );
                 }

                 # engine tank
                 else {
                     itank = i;
                 }

                 me.crosstransfer( icross, nbtanks, itank )
            }
        }
   }
}

Fuel.crossfeed = func {
   var nbtanks = 0;
   var inboard = 0;
   var icross = 0;
   var crossengine = constant.FALSE;
   var cross = constant.FALSE;

   for( var i=0; i < constantaero.NBENGINES; i=i+1 ) {
        if( me.engines[i].getChild("cross-feed").getValue() ) {
            crossengine = constant.TRUE;

            # engine tank
            if( !me.tanksystem.empty( i ) ) {
                nbtanks = nbtanks + 1;
                cross = constant.TRUE;
            } else {
                cross = constant.FALSE;
            }
            me.crosstanks[i].getChild("cross").setValue(cross);

            # inboard tank
            if( constantaero.isInboardEngine( i ) ) {
                inboard = constantaero.outboardTank( i );
                if( !me.tanksystem.empty( inboard ) ) {
                    nbtanks = nbtanks + 1;
                    cross = constant.TRUE;
                } else {
                    cross = constant.FALSE;
                }
                me.crosstanks[inboard].getChild("cross").setValue(cross);
            }
        }
        else {
            crossengine = constant.FALSE;
        }

        me.crossengines[i].getChild("cross").setValue(crossengine);
   }

   # supplies the virtual cross feed tank of each connected engine
   if( nbtanks > 0 ) {
       # record level of cross feed tanks
       me.crosslevel();

       # completes the cross feed tanks
       for( var i=0; i < constantaero.NBTANKS ; i=i+1 ) {
            if( me.crosstanks[i].getChild("cross").getValue() ) {
                for( var j=0; j < constantaero.NBENGINES; j=j+1 ) {
                     if( me.crossengines[j].getChild("cross").getValue() and
                         !me.engines[j].getChild("firewall").getValue() ) {
                         icross = constantaero.NBTANKS + j;
                         me.crosstransfer( icross, nbtanks, i )
                     }
                }
            }
       }
   }
}

Fuel.red_fuel = func {
   var value = constant.FALSE;

   for( var i = 0; i < constantaero.NBENGINES; i = i+1 ) {
        if( me.sysengines[i].getChild("fuel-pressure").getValue() < me.PRESSURELOW ) {
            value = constant.TRUE;
        }
        else {
            value = constant.FALSE;
        }

        me.sysengines[i].getChild("fuel-pressure-low").setValue( value );
   }
}

Fuel.crosslevel = func {
   var icross = 0;
   var levellb = 0.0;

   for( var i=0; i < constantaero.NBENGINES; i=i+1 ) {
        icross = constantaero.NBTANKS + i;
        levellb = me.tanksystem.getlevellb( icross );
        me.crosstanks[icross].getChild("level-lb").setValue(levellb);
   }
}

Fuel.crosstransfer = func( icross, nbtanks, itank ) {
   if( me.tanks[itank].getChild("shut-off").getValue() == 1 ) {
       var contentlb = me.tanksystem.getcontentlb( icross );
       var offsetlb = contentlb - me.crosstanks[icross].getChild("level-lb").getValue();
       var pumplb = offsetlb / nbtanks;

       me.tanksystem.transfertanks( icross, itank, pumplb );
   }
}


# =====
# TANKS
# =====

# adds an indirection to convert the tank name into an array index.

Tanks = {};

Tanks.new = func {
# tank contents, to be initialised from XML
   var obj = { parents : [Tanks], 

               pumpsystem : Pump.new(),

               CONTENTLB : { "1" : 0.0, "2" : 0.0, "3" : 0.0, "4" : 0.0, "5" : 0.0, "2A" : 0.0, "3A" : 0.0,
                             "C1" : 0.0, "C2" : 0.0, "C3" : 0.0, "C4" : 0.0 },
               TANKINDEX : { "1" : 0, "2" : 1, "3" : 2, "4" : 3, "5" : 4, "2A" : 5, "3A" : 6,
                             "C1" : 7, "C2" : 8, "C3" : 9, "C4" : 10 },
               TANKNAME : [ "1", "2", "3", "4", "5", "2A", "3A", "C1", "C2", "C3", "C4" ],
               nb_tanks : 0,

               fillings : nil,
               tanks : nil
             };

    obj.init();

    return obj;
}

Tanks.init = func {
    me.tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
    me.fillings = props.globals.getNode("/systems/fuel/tanks").getChildren("filling");

    me.nb_tanks = size(me.tanks);

    me.initcontent();
}

# fuel initialization
Tanks.initcontent = func {
   var densityppg = 0.0;

   for( var i=0; i < me.nb_tanks; i=i+1 ) {
        densityppg = me.tanks[i].getChild("density-ppg").getValue();
        me.CONTENTLB[me.TANKNAME[i]] = me.tanks[i].getChild("capacity-gal_us").getValue() * densityppg;
   }
}

# change by dialog
Tanks.menu = func {
   var value = getprop("/systems/fuel/tanks/dialog");

   for( var i=0; i < size(me.fillings); i=i+1 ) {
        if( me.fillings[i].getChild("comment").getValue() == value ) {
            me.load( i );

            # for aircraft-data
            setprop("/systems/fuel/presets",i);
            break;
        }
   }
}

# fuel configuration
Tanks.presetfuel = func {
   var fuel = getprop("/systems/fuel/presets");
   var dialog = getprop("/systems/fuel/tanks/dialog");
   var value = "";

   # default is 0
   if( fuel == nil ) {
       fuel = 0;
   }

   if( fuel < 0 or fuel >= size(me.fillings) ) {
       fuel = 0;
   } 

   # copy to dialog
   if( dialog == "" or dialog == nil ) {
       value = me.fillings[fuel].getChild("comment").getValue();
       setprop("/systems/fuel/tanks/dialog", value);
   }

   me.load( fuel );
}

Tanks.load = func( fuel ) {
   var level = 0.0;
   var presets = me.fillings[fuel].getChildren("tank");
   var child = nil;

   for( var i=0; i < size(presets); i=i+1 ) {
        child = presets[i].getChild("level-gal_us");
        if( child != nil ) {
            level = child.getValue();
        }

        # new load through dialog
        else {
            level = me.CONTENTLB[me.TANKNAME[i]] * constant.LBTOGALUS;
        } 
        me.pumpsystem.setlevel(i, level);
   } 
}

Tanks.getcontentlb = func( index ) {
   return me.CONTENTLB[me.TANKNAME[index]];
}

Tanks.getlevellb = func( index ) {
   return me.pumpsystem.getlevellb( index );
}

Tanks.empty = func( index ) {
   return me.pumpsystem.empty( index );
}

Tanks.transfertanks = func( dest, sour, pumplb ) {
   me.pumpsystem.transfertanks( dest, me.CONTENTLB[me.TANKNAME[dest]], sour, pumplb );
}


# ==========
# FUEL PUMPS
# ==========

# does the transfers between the tanks

Pump = {};

Pump.new = func {
   var obj = { parents : [Pump],

               tanks : nil 
         };

   obj.init();

   return obj;
}

Pump.init = func {
   me.tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
}

Pump.getlevel = func( index ) {
   var tankgalus = me.tanks[index].getChild("level-gal_us").getValue();

   return tankgalus;
}

Pump.getlevellb = func( index ) {
   var tanklb = me.getlevel(index) * constant.GALUSTOLB;

   return tanklb;
}

Pump.empty = func( index ) {
   var tankgal = me.getlevel(index);
   var result = constant.FALSE;

   if( tankgal == 0.0 ) {
       result = constant.TRUE;
   }

   return result;
}

Pump.setlevel = func( index, levelgalus ) {
   me.tanks[index].getChild("level-gal_us").setValue(levelgalus);
}

Pump.transfertanks = func( idest, contentdestlb, isour, pumplb ) {
   var tankdestlb = me.tanks[idest].getChild("level-gal_us").getValue() * constant.GALUSTOLB;
   var tanksourlb = me.tanks[isour].getChild("level-gal_us").getValue() * constant.GALUSTOLB;
   var maxdestlb = contentdestlb - tankdestlb;
   var maxsourlb = tanksourlb - 0;
   var tankdestgalus = 0.0;
   var tanksourgalus = 0.0;

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
           me.tanks[isour].getChild("level-gal_us").setValue(tanksourgalus);
           tankdestgalus = tankdestlb / constant.GALUSTOLB;
           me.tanks[idest].getChild("level-gal_us").setValue(tankdestgalus);
       }
   }
}
