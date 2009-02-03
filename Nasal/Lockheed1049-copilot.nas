# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ===============
# VIRTUAL COPILOT
# ===============

VirtualCopilot = {};

VirtualCopilot.new = func {
   var obj = { parents : [VirtualCopilot,VirtualCrew,System],

               autopilotsystem : nil,
               crewscreen : nil,
               engineercrew : nil,
 
               nightlighting : Nightlighting.new(),

               COPILOTSEC : 2.0,

               rates : 0.0,

               ROLLDEG : 2.0,                                 # roll to swap to next waypoint

               WPTNM : 4.0,                                   # distance to swap to next waypoint

               headingmode : "",

               followswaypoint : constant.FALSE,
               waypointexist : constant.FALSE,
               waypointtoggle : constant.FALSE
         };

   obj.init();

   return obj;
};

VirtualCopilot.init = func {
   var path = "/systems/copilot";

   me.inherit_system(path);
   me.inherit_virtualcrew(path);

   me.rates = me.COPILOTSEC;
   me.run();
}

VirtualCopilot.set_relation = func( autopilot, crew, engineer ) {
   me.autopilotsystem = autopilot;
   me.engineercrew = engineer;
   me.crewscreen = crew;
}

VirtualCopilot.toggleexport = func {
   var launch = constant.FALSE;

   if( !me.itself["copilot"].getChild("activ").getValue() ) {
       launch = constant.TRUE;
   }

   me.itself["copilot"].getChild("activ").setValue(launch);
       
   if( launch and !me.is_running() ) {
       # must switch again lights
       me.nightlighting.set_task();

       me.schedule();
   }

   # clear
   else {
       me.none();
   }
}

VirtualCopilot.throttleexport = func {
   var throttle = constant.FALSE;
   var mode = "speed-with-throttle";

   me.state = "";

   # ctrl-S toggles virtual copilot
   if( me.dependency["autopilot"].getChild("speed").getValue() != mode ) {
       if( !me.itself["copilot"].getChild("activ").getValue() ) {
           me.togglecrewexport();
       }

       throttle = constant.TRUE;

       me.log("throttle");
   }

   else {
       mode = "";

       me.log("no-throttle");
   }


   # feedback
   me.itself["root"].getChild("throttle").setValue(throttle);
   me.itself["root"].getChild("state").setValue(me.state);

   me.dependency["autopilot"].getChild("speed").setValue( mode );
}

VirtualCopilot.schedule = func {
   me.reset();

   if( me.dependency["crew"].getChild("serviceable").getValue() ) {
       me.supervisor();
   }

   me.run();
}

VirtualCopilot.fastschedule = func {
   me.state = "";

   me.waypointtoggle = me.itself["copilot"].getChild("fg-waypoint").getValue();
   me.followswaypoint = me.itself["copilot"].getChild("waypoint").getValue();
   me.headingmode = me.dependency["autopilot"].getChild("heading").getValue();

   me.waypointexist = me.has_waypoint();

   if( me.waypointexist ) {
       me.lockwaypointroll();
       me.followplan();
   }

   else {
       me.holdheading();
   }

   if( me.state != "" ) {
       me.timestamp();
   }
}

VirtualCopilot.run = func {
   if( me.itself["copilot"].getChild("activ").getValue() ) {
       me.set_running();

       me.rates = me.speed_ratesec( me.rates );
       settimer( func { me.schedule(); }, me.rates );
   }
}

VirtualCopilot.supervisor = func {
   me.rates = me.COPILOTSEC;

   if( me.itself["copilot"].getChild("activ").getValue() ) {
       me.set_activ();

       me.nightlighting.copilot( me );

       me.rates = me.randoms( me.rates );
       me.timestamp();
   }

   me.itself["root"].getChild("activ").setValue(me.is_activ());
}

VirtualCopilot.followplan = func {
   # autopilot is already on
   if( me.headingmode == "dg-heading-hold" ) {
       if( me.waypointexist ) {
           # waypoint input toggles virtual copilot, which follows waypoint.
           if( !me.itself["copilot"].getChild("activ").getValue() ) {
               if( me.waypointtoggle and me.followswaypoint ) {
                   me.togglecrewexport();
               }
           }

           # virtual copilot is already on
           elsif( me.followswaypoint ) {
               me.dependency["autopilot"].getChild("heading").setValue("true-heading-hold");
               me.log("waypoint");
           }
       }
   }

   # autopilot may not be on
   elsif( me.headingmode == "true-heading-hold" ) {
       # there is no more waypoint, or virtual copilot doesn't follow waypoint.
       if( !me.waypointexist or !me.followswaypoint ) {
           me.holdheading();
       }

       # waypoint input toggles virtual copilot
       elsif( me.waypointtoggle ) {
           if( !me.itself["copilot"].getChild("activ").getValue() ) {
               me.togglecrewexport();
           }
       }
   }
}

# avoid strong roll near a waypoint
VirtualCopilot.lockwaypointroll = func {
     var lastnm = 0.0;
     var rolldeg = 0.0;
     var distancenm = me.itself["waypoint"][0].getChild("dist").getValue();

     # next waypoint
     if( distancenm != nil ) {
         # avoids strong roll
         if( distancenm < me.WPTNM ) {
             lastnm = me.itself["root"].getChild("waypoint-nm").getValue();

             # pop waypoint
             rolldeg =  me.noinstrument["roll"].getValue();
             if( distancenm > lastnm or rolldeg < - me.ROLLDEG or rolldeg > me.ROLLDEG ) {
                 if( me.headingmode == "true-heading-hold" ) {
                     setprop("/autopilot/route-manager/input","@pop");
                 }
             }
         }

         me.itself["root"].getChild("waypoint-nm").setValue(distancenm);
     }
}

VirtualCopilot.togglecrewexport = func {
   me.toggleexport();
   me.engineercrew.toggleexport();
   me.crewscreen.toggleexport();
}

VirtualCopilot.holdheading = func {
   # keep the current heading
   if( me.headingmode == "true-heading-hold" ) {
       me.autopilotsystem.real();
   }
}

VirtualCopilot.nothrottle = func {
   me.dependency["autopilot"].getChild("speed").setValue("");
   me.itself["root"].getChild("throttle").setValue("");
}

VirtualCopilot.none = func {
   me.holdheading();
   me.nothrottle();
}

VirtualCopilot.has_waypoint = func {
   var result = constant.FALSE;
   var ident = me.dependency["waypoint"][0].getChild("id").getValue();

   if( ident != nil ) {
       if( ident != "" ) {
           result = constant.TRUE;
       }
   }

   return result;
}
