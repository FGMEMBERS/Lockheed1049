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
   var obj = { parents : [Fuel,System],

               tanksystem : Tanks.new(),
               parser : FuelXML.new(),

               presets : 0,                                # saved state

               PUMPSEC : 1,                                # refresh rate

               PUMPLBPSEC : 25,                            # 25 lb/s for 1 pump.

               PRESSURELOW : 0.5,
         };

   obj.init();

   return obj;
};

Fuel.init = func {
   me.inherit_system("/systems/fuel");

   me.PUMPPMIN0 = constant.MINUTETOSECOND / me.PUMPSEC;
   me.PUMPLB0 = me.PUMPLBPSEC * me.PUMPSEC;
   me.PUMPPMIN = me.PUMPPMIN0;
   me.PUMPLB = me.PUMPLB0;

   me.tanksystem.initinstrument();
   me.tanksystem.presetfuel();

   me.savestate();
}

Fuel.menuexport = func {
   me.tanksystem.menu();

   me.savestate();
}

Fuel.reinitexport = func {
   # restore for reinit
   me.itself["root"].getChild("presets").setValue( me.presets );

   me.tanksystem.presetfuel();
   me.savestate();
}

Fuel.savestate = func {
   # backup for reinit
   me.presets = me.itself["root"].getChild("presets").getValue();
}

Fuel.schedule = func {
   var speedup = me.noinstrument["speed-up"].getValue();

   if( speedup > 1 ) {
       me.PUMPPMIN = me.PUMPPMIN0 / speedup;
       me.PUMPLB = me.PUMPLB0 * speedup;
   }
   else {
       me.PUMPPMIN = me.PUMPPMIN0;
       me.PUMPLB = me.PUMPLB0;
   }

   me.pumping();

   me.red_fuel();
}

Fuel.pumping = func {
   if( me.itself["root"].getChild("serviceable").getValue() ) {
       me.parser.schedule( me.PUMPLB, me.tanksystem );
   }
}

Fuel.red_fuel = func {
   var value = constant.FALSE;

   for( var i = 0; i < constantaero.NBENGINES; i = i+1 ) {
        if( me.dependency["engine"][i].getChild("fuel-pressure").getValue() < me.PRESSURELOW ) {
            value = constant.TRUE;
        }
        else {
            value = constant.FALSE;
        }

        me.dependency["engine"][i].getChild("fuel-pressure-low").setValue( value );
   }
}


# =====
# TANKS
# =====

# adds an indirection to convert the tank name into an array index.

Tanks = {};

Tanks.new = func {
# tank contents, to be initialised from XML
   var obj = { parents : [Tanks,TankXML], 

               CONTENTLB : { "1" : 0.0, "2" : 0.0, "3" : 0.0, "4" : 0.0, "5" : 0.0, "2A" : 0.0, "3A" : 0.0,
                             "C1" : 0.0, "C2" : 0.0, "C3" : 0.0, "C4" : 0.0 },
               TANKINDEX : { "1" : 0, "2" : 1, "3" : 2, "4" : 3, "5" : 4, "2A" : 5, "3A" : 6,
                             "C1" : 7, "C2" : 8, "C3" : 9, "C4" : 10 },
               TANKNAME : [ "1", "2", "3", "4", "5", "2A", "3A", "C1", "C2", "C3", "C4" ]
             };

    obj.init();

    return obj;
}

Tanks.init = func {
    me.inherit_tankXML();
}

