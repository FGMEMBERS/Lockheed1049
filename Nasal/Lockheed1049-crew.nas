# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ===============
# VIRTUAL COPILOT
# ===============

VirtualCopilot = {};

VirtualCopilot.new = func {
   obj = { parents : [VirtualCopilot],

           autopilotsystem : nil,

           copilot : nil,
           crew : nil,
           crewcontrol : nil,
           waypoints : nil,

           CRUISESEC : 15.0,
           MINIMIZESEC : 0.0,
           COPILOTSEC : 3.0,
           NOSEC : 0.0,

           times : 0.0,

           FLIGHTFT : 1000.0,

           headingmode : "",
           activ : constant.FALSE,
           state : ""
         };

   obj.init();

   return obj;
};

VirtualCopilot.init = func {
   me.copilot = props.globals.getNode("/systems/crew/copilot");
   me.crew = props.globals.getNode("/systems/crew");
   me.crewcontrol = props.globals.getNode("/controls/crew");
   me.waypoints = props.globals.getNode("/autopilot/route-manager").getChildren("wp");

   me.MINIMIZESEC = me.crewcontrol.getChild("minimized-s").getValue();
   if( me.MINIMIZESEC < me.COPILOTSEC ) {
      print( "/systems/crew/minimize-s should be above ", me.COPILOTSEC, " seconds : ", me.MINIMIZESEC );
   }
}

VirtualCopilot.set_relation = func( autopilot ) {
   me.autopilotsystem = autopilot;
}

VirtualCopilot.toggleexport = func {
   if( !me.crewcontrol.getChild("copilot").getValue() ) {
       me.crewcontrol.getChild("copilot").setValue(constant.TRUE);
   }
   else {
       me.crewcontrol.getChild("copilot").setValue(constant.FALSE);
   }

   me.supervisor();
   me.maximize();
}

VirtualCopilot.minimizeexport = func {
   if( !me.crew.getChild("minimized").getValue() ) {
       me.crew.getChild("minimized").setValue(constant.TRUE);
   }
   else {
       me.maximize();
   }
}

VirtualCopilot.schedule = func {
   if( me.crew.getChild("serviceable").getValue() ) {
       me.minimize();
   }
}

VirtualCopilot.slowschedule = func {
   if( me.crew.getChild("serviceable").getValue() ) {
       me.supervisor();
   }
}

VirtualCopilot.maximize = func {
   me.crew.getChild("minimized").setValue(constant.FALSE);
   me.times = me.NOSEC;
}

VirtualCopilot.minimize = func {
   if( !me.crew.getChild("minimized").getValue() ) {
       me.times = me.times + me.COPILOTSEC;
       if( me.times >= me.MINIMIZESEC ) {
           me.minimizeexport();
       }
   }
}

VirtualCopilot.supervisor = func {
   me.activ = constant.FALSE;
   me.headingmode = getprop("/autopilot/locks/heading");

   if( me.crewcontrol.getChild("copilot").getValue() ) {
       me.state = "";

       if( getprop("/position/altitude-agl-ft") > me.FLIGHTFT ) {
           me.activ = constant.TRUE;

           me.holdspeed();
           me.followplan();
       }
       else {
           me.none();
       }

       me.copilot.getChild("state").setValue(me.state);
       me.copilot.getChild("time").setValue(getprop("/sim/time/gmt-string"));
   }
   else {
       me.none();
   }

   me.copilot.getChild("activ").setValue(me.activ);
}

VirtualCopilot.holdspeed = func {
   mode = "speed-with-throttle";
   if( getprop("/autopilot/locks/speed") != mode ) {
       setprop("/autopilot/locks/speed",mode);
       me.log("throttle");
   }
}

VirtualCopilot.followplan = func {
   # follows waypoints
   if( me.headingmode == "dg-heading-hold" ) {
       ident = me.waypoints[0].getChild("id").getValue();
       if( ident != nil ) {
           if( ident != "" ) {
               setprop("/autopilot/locks/heading","true-heading-hold");
               me.log("waypoint");
           }
       }
   }

   elsif( me.headingmode == "true-heading-hold" ) {
       ident = me.waypoints[0].getChild("id").getValue();
       if( ident == nil or ident == "" ) {
           me.holdheading();
       }
   }
}

VirtualCopilot.holdheading = func {
   # keep the current heading
   if( me.headingmode == "true-heading-hold" ) {
       me.autopilotsystem.real();
   }
}

VirtualCopilot.none = func {
   me.holdheading();

   setprop("/autopilot/locks/speed","");
}

VirtualCopilot.log = func( message ) {
    me.state = me.state ~ " " ~ message;
}
