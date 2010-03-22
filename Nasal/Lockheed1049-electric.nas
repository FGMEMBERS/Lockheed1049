# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ========
# LIGHTING
# ========

Lighting = {};

Lighting.new = func {
   var obj = { parents : [Lighting],

               landing : LandingLight.new(),
               internal : LightLevel.new()
         };

   obj.init();

   return obj;
};

Lighting.init = func {
   var beacon_switch = props.globals.getNode("controls/lighting/beacon", constant.FALSE);

   aircraft.light.new("controls/lighting/flash", [ 0.10, 1.20 ], beacon_switch);
}

Lighting.schedule = func {
   me.landing.schedule();
   me.internal.schedule();
}


# =============
# LANDING LIGHT
# =============

LandingLight = {};

LandingLight.new = func {
   var obj = { parents : [LandingLight,System],

               EXTENDSEC : 8.0,                                # time to extend a landing light
 
               EXTENDNORM : 1.0,
               ERRORNORM : 0.1,                                # Nasal interpolate may not reach 1.0
               RETRACTNORM : 0.0
         };

   obj.init();

   return obj;
};

LandingLight.init = func {
   me.inherit_system("/systems/lighting");
}

LandingLight.schedule = func {
   if( me.itself["root"].getChild("serviceable").getValue() ) {
       if( me.landingextended() ) {
           me.extendexport();
       }
   }
}
LandingLight.landingextended = func {
   var extension = constant.FALSE;

   # because of motor failure, may be extended with switch off, or switch on and not yet extended
   for( var i=0; i < constantaero.NBINSTRUMENTS; i=i+1) {
        if( me.itself["landing"][i].getChild("position").getValue() > 0 or
            me.itself["landing"][i].getChild("extend").getValue() ) {
            extension = constant.TRUE;
            break;
        }
   }

   return extension;
}

LandingLight.landingmotor = func( light, present, target ) {
   var durationsec = 0.0;

   if( present < me.RETRACTNORM + me.ERRORNORM ) {
       if( target == me.EXTENDNORM ) {
           durationsec = me.EXTENDSEC;
       }
       else {
           durationsec = 0.0;
       }
   }

   elsif( present > me.EXTENDNORM - me.ERRORNORM and present < me.EXTENDNORM + me.ERRORNORM ) {
       if( target == me.RETRACTNORM ) {
           durationsec = me.EXTENDSEC;
       }
       else {
           durationsec = 0.0;
       }
   }

   # motor in movement
   else {
       durationsec = 0.0;
   }

   if( durationsec > 0.0 ) {
       interpolate(light,target,durationsec);
   }
}

LandingLight.extendexport = func {
   var target = 0.0;
   var value = 0.0;
   var result = 0.0;
   var light = "";

   if( me.dependency["electric"].getChild("specific").getValue() ) {
       for( var i=0; i < constantaero.NBINSTRUMENTS; i=i+1 ) {
            if( me.itself["landing"][i].getChild("extend").getValue() ) {
                value = me.EXTENDNORM;
            }
            else {
                value = me.RETRACTNORM;
            }

            result = me.itself["landing"][i].getChild("position").getValue();
            if( result != value ) {
                light = "/controls/lighting/external/landing[" ~ i ~ "]/position";
                me.landingmotor( light, result, value );
            }
       }
   }
}


# ===========
# LIGHT LEVEL
# ===========

LightLevel = {};

LightLevel.new = func {
   var obj = { parents : [LightLevel,System],

               NOLIGHT : 0.0
         };

   obj.init();

   return obj;
};

LightLevel.init = func {
   me.inherit_system("/systems/lighting");
}

LightLevel.schedule = func {
   me.pilot();

   me.side( "pilot", "side" );
   me.side( "pilot", "chart" );

   me.side( "copilot", "side" );
   me.side( "copilot", "chart" );

   me.engineer();
}

LightLevel.pilot = func {
   var value = me.NOLIGHT;
   var result = me.NOLIGHT;
   var pilotlight = me.NOLIGHT;
   var copilotlight = me.NOLIGHT;

   # cannot add pilot and copilot red lights
   value = me.itself["internal-ctrl"].getNode("pilot").getChild("panel").getValue();
   if( value > result ) {
       result = value;
   }
   if( value > me.NOLIGHT ) {
       pilotlight = value + me.dependency["instrument"].getValue();
   }

   value = me.itself["internal-ctrl"].getNode("copilot").getChild("panel").getValue();
   if( value > result ) {
       result = value;
   }
   if( value > me.NOLIGHT ) {
       copilotlight = value + me.dependency["instrument"].getValue();
   }

   me.itself["internal"].getChild("panel-light").setValue( result );

   # user customization of instrument lighting
   me.itself["internal"].getNode("pilot").getChild("instrument-light").setValue( pilotlight );
   me.itself["internal"].getNode("copilot").getChild("instrument-light").setValue( copilotlight );
}

LightLevel.side = func( seat, panel ) {
   var result = me.NOLIGHT;

   if( me.itself["internal-ctrl"].getNode(seat).getChild(panel ~ "-on").getValue() ) {
       result = me.itself["internal-ctrl"].getNode(seat).getChild(panel).getValue();
   }

   me.itself["internal"].getNode(seat).getChild(panel ~ "-light").setValue( result );
}

LightLevel.engineer = func {
   var result = me.NOLIGHT;
   var engineerlight = me.NOLIGHT;

   value = me.itself["internal-ctrl"].getNode("engineer").getChild("flood").getValue();
   if( value > result ) {
       result = value;
   }
   if( value > me.NOLIGHT ) {
       engineerlight = value + me.dependency["instrument"].getValue();
   }

   me.itself["internal"].getNode("engineer").getChild("flood-light").setValue( result );

   # user customization of instrument lighting
   me.itself["internal"].getNode("engineer").getChild("instrument-light").setValue( engineerlight );
}
