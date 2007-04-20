# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# IMPORTANT :
# always uses /consumables/fuel/tank[0]/level-gal_us, because /level-lb seems not synchronized
# with level-gal_us, during the time of a procedure.


# ===========
# FUEL SYSTEM
# ===========

Fuel = {};

Fuel.new = func {
   obj = { parents : [Fuel],

           tanksystem : Tanks.new(),

           crosstanks : nil,
           crossengines : nil,
           engines : nil,

           SPEEDUPSEC : 2,             # refresh rate

           NB_ENGINES : 4,
           NB_TANKS : 7
         };

   obj.init();

   return obj;
};

Fuel.init = func {
   me.crosstanks = props.globals.getNode("/systems/fuel-pump/tanks").getChildren("tank");
   me.crossengines = props.globals.getNode("/systems/fuel-pump/engines").getChildren("engine");
   me.engines = props.globals.getNode("/controls/fuel").getChildren("engine");

   me.tanksystem.presetfuel();
}

Fuel.schedule = func {
   me.crossfeed();
}

Fuel.menuexport = func {
   me.tanksystem.menu();
}

# cross feed emulation
Fuel.crossfeed = func {
   nbtanks = 0;
   for( i=0; i < me.NB_ENGINES; i=i+1 ) {
        if( me.engines[i].getChild("cross-feed").getValue() ) {
            crossengine = constant.TRUE;
            # engine tank
            if( !me.tanksystem.empty(i) ) {
                nbtanks = nbtanks + 1;
                cross = constant.TRUE;
            } else {
                cross = constant.FALSE;
            }
            me.crosstanks[i].getChild("cross").setValue(cross);
            # inboard tank
            if( i == 1 or i == 2 ) {
                inboard = me.NB_ENGINES + i;
                if( !me.tanksystem.empty(inboard) ) {
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
       for( i=0; i < me.NB_ENGINES; i=i+1 ) {
            icross = me.NB_TANKS + i;
            levellb = me.tanksystem.getlevellb( icross );
            me.crosstanks[icross].getChild("level-lb").setValue(levellb);
       }

       # completes the cross feed tanks
       for( i=0; i < me.NB_TANKS ; i=i+1 ) {
            if( me.crosstanks[i].getChild("cross").getValue() ) {
                 for( j=0; j < me.NB_ENGINES; j=j+1 ) {
                     if( me.crossengines[j].getChild("cross").getValue() ) {
                         icross = me.NB_TANKS + j;
                         contentlb = me.tanksystem.getcontentlb( icross );
                         offsetlb = contentlb - me.crosstanks[icross].getChild("level-lb").getValue();
                         pumplb = offsetlb / nbtanks;
                         me.tanksystem.transfertanks( icross, i, pumplb );
                     }
                }
            }
       }
   }
}


# =====
# TANKS
# =====

# adds an indirection to convert the tank name into an array index.

Tanks = {};

Tanks.new = func {
# tank contents, to be initialised from XML
   obj = { parents : [Tanks], 

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
   for( i=0; i < me.nb_tanks; i=i+1 ) {
        densityppg = me.tanks[i].getChild("density-ppg").getValue();
        me.CONTENTLB[me.TANKNAME[i]] = me.tanks[i].getChild("capacity-gal_us").getValue() * densityppg;
   }
}

# change by dialog
Tanks.menu = func {
   value = getprop("/systems/fuel/tanks/dialog");
   for( i=0; i < size(me.fillings); i=i+1 ) {
        if( me.fillings[i].getChild("comment").getValue() == value ) {
            me.load( i );

            # for aircraft-data
            setprop("/sim/presets/fuel",i);
            break;
        }
   }
}

# fuel configuration
Tanks.presetfuel = func {
   # default is 0
   fuel = getprop("/sim/presets/fuel");
   if( fuel == nil ) {
       fuel = 0;
   }

   if( fuel < 0 or fuel >= size(me.fillings) ) {
       fuel = 0;
   } 

   # copy to dialog
   dialog = getprop("/systems/fuel/tanks/dialog");
   if( dialog == "" or dialog == nil ) {
       value = me.fillings[fuel].getChild("comment").getValue();
       setprop("/systems/fuel/tanks/dialog", value);
   }

   me.load( fuel );
}

Tanks.load = func( fuel ) {
   presets = me.fillings[fuel].getChildren("tank");
   for( i=0; i < size(presets); i=i+1 ) {
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
   obj = { parents : [Pump],

           tanks : nil 
         };

   obj.init();

   return obj;
}

Pump.init = func {
   me.tanks = props.globals.getNode("/consumables/fuel").getChildren("tank");
}

Pump.getlevel = func( index ) {
   tankgalus = me.tanks[index].getChild("level-gal_us").getValue();

   return tankgalus;
}

Pump.getlevellb = func( index ) {
   tanklb = me.getlevel(index) * constant.GALUSTOLB;

   return tanklb;
}

Pump.empty = func( index ) {
   tankgal = me.getlevel(index);

   if( tankgal == 0.0 ) {
       result = constant.TRUE;
   }
   else {
       result = constant.FALSE;
   }

   return result;
}

Pump.setlevel = func( index, levelgalus ) {
   me.tanks[index].getChild("level-gal_us").setValue(levelgalus);
}

Pump.transfertanks = func( idest, contentdestlb, isour, pumplb ) {
   tankdestlb = me.tanks[idest].getChild("level-gal_us").getValue() * constant.GALUSTOLB;
   maxdestlb = contentdestlb - tankdestlb;
   tanksourlb = me.tanks[isour].getChild("level-gal_us").getValue() * constant.GALUSTOLB;
   maxsourlb = tanksourlb - 0;
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
