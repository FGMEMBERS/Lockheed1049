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

               redseat : { "pilot" : constant.FALSE, "copilot" : constant.FALSE },

               WHITELIGHT : 1.0,
               REDDISH : 0.1,
               NOLIGHT : 0.0
         };

   obj.init();

   return obj;
};

LightLevel.init = func {
   me.inherit_system("/systems/lighting");

   me.redseat["pilot"] = me.itself["internal-ctrl"].getNode("pilot").getChild("chart-red").getValue();
   me.redseat["copilot"] = me.itself["internal-ctrl"].getNode("copilot").getChild("chart-red").getValue();
}

LightLevel.schedule = func {
   me.pilot();

   me.side( "pilot" );
   me.chart( "pilot" );

   me.side( "copilot" );
   me.chart( "copilot" );

   me.overhead();
   me.engineer();
}

LightLevel.pilot = func {
   var value = me.NOLIGHT;
   var result = me.NOLIGHT;
   var pilotlight = me.NOLIGHT;
   var copilotlight = me.NOLIGHT;
   var greenblue = me.NOLIGHT;
   var light = 0;
   var path = "";
   var child = me.itself["internal"].getNode("panel").getChild("panel-light");
   var currentpath = child.getAliasTarget().getPath();


   # cannot add pilot and copilot red lights
   value = me.itself["internal-ctrl"].getNode("pilot").getChild("panel").getValue();
   if( value > result ) {
       light = 1;
       result = value;
   }
   if( value > me.NOLIGHT ) {
       pilotlight = value + me.dependency["instrument"].getValue();
   }

   value = me.itself["internal-ctrl"].getNode("copilot").getChild("panel").getValue();
   if( value > result ) {
       light = 2;
       result = value;
   }
   if( value > me.NOLIGHT ) {
       copilotlight = value + me.dependency["instrument"].getValue();
   }

   # cannot mix red with white emergency
   value = me.itself["internal-ctrl"].getNode("pilot").getChild("emergency").getValue();
   if( value > result ) {
       light = 3;
       result = value;
   }


   if( light > 0 ) {
       if( light == 1 ) {
           path = me.itself["internal-ctrl"].getNode("pilot").getChild("panel").getPath();
           greenblue = me.REDDISH;
       }
       elsif( light == 2 ) {
           path = me.itself["internal-ctrl"].getNode("copilot").getChild("panel").getPath();
           greenblue = me.REDDISH;
       }
       else {
           path = me.itself["internal-ctrl"].getNode("pilot").getChild("emergency").getPath();
           greenblue = me.WHITELIGHT;
       }

       if( currentpath != path ) {
           child.unalias();
           child.alias( path );

           me.itself["internal"].getNode("panel").getChild("panel-green").setValue( greenblue );
           me.itself["internal"].getNode("panel").getChild("panel-blue").setValue( greenblue );
       }
   }


   # USER customization of instrument lighting (not real)
   me.itself["internal"].getNode("pilot").getChild("instrument-light").setValue( pilotlight );
   me.itself["internal"].getNode("copilot").getChild("instrument-light").setValue( copilotlight );
}

LightLevel.side = func( seat ) {
   var result = me.NOLIGHT;

   if( me.itself["internal-ctrl"].getNode(seat).getChild("side-on").getValue() ) {
       result = me.itself["internal-ctrl"].getNode(seat).getChild("side").getValue();
   }

   me.itself["internal"].getNode(seat).getChild("side-light").setValue( result );
}

LightLevel.chart = func( seat ) {
   var path = "";
   var filter = constant.FALSE;
   var child = me.itself["internal"].getNode(seat).getChild("chart-light");
   var currentpath = child.getAliasTarget().getPath();

   if( me.itself["internal-ctrl"].getNode(seat).getChild("chart-on").getValue() ) {
       path = me.itself["internal-ctrl"].getNode(seat).getChild("chart").getPath();
       if( currentpath != path ) {
           child.unalias();
           child.alias( path );
       }
   }

   else {
       path = me.itself["internal-ctrl"].getNode(seat).getChild("chart-on").getPath();
       if( currentpath != path ) {
           child.unalias();
           child.alias( path );
       }
   }

   filter = me.itself["internal-ctrl"].getNode(seat).getChild("chart-red").getValue();
   if( filter != me.redseat[seat] ) {
       if( filter ) {
           me.itself["internal"].getNode(seat).getChild("chart-green").setValue( me.REDDISH );
           me.itself["internal"].getNode(seat).getChild("chart-blue").setValue( me.REDDISH );
       }
       else
       {
           me.itself["internal"].getNode(seat).getChild("chart-green").setValue( me.WHITELIGHT );
           me.itself["internal"].getNode(seat).getChild("chart-blue").setValue( me.WHITELIGHT );
       }

       me.redseat[seat] = filter;
   }
}

LightLevel.overhead = func {
   var path = "";
   var child = me.itself["internal"].getNode("overhead").getChild("light");
   var currentpath = child.getAliasTarget().getPath();

   # white has priority over reddish
   if( me.itself["internal-ctrl"].getNode("overhead").getChild("on").getValue() ) {
       path = me.itself["internal-ctrl"].getNode("overhead").getChild("on").getPath();
       if( currentpath != path ) {
           child.unalias();
           child.alias( path );

           me.itself["internal"].getNode("overhead").getChild("green").setValue( me.WHITELIGHT );
           me.itself["internal"].getNode("overhead").getChild("blue").setValue( me.WHITELIGHT );
       }
   }

   else {
       path = me.itself["internal-ctrl"].getNode("overhead").getChild("panel").getPath();
       if( currentpath != path ) {
           child.unalias();
           child.alias( path );

           me.itself["internal"].getNode("overhead").getChild("green").setValue( me.REDDISH );
           me.itself["internal"].getNode("overhead").getChild("blue").setValue( me.REDDISH );
       }
   }
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
