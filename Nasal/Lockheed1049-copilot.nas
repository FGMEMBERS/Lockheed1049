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

   me.context();

   if( !me.itself["root-ctrl"].getChild("activ").getValue() ) {
       launch = constant.TRUE;
   }

   me.itself["root-ctrl"].getChild("activ").setValue(launch);
       
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

VirtualCopilot.lightingexport = func {
   me.nightlighting.copilotexport();
}

VirtualCopilot.throttleexport = func {
   var throttle = constant.FALSE;
   var mode = "";

   me.context();

   # ctrl-S toggles virtual copilot
   if( !me.is_autothrottle() ) {
       me.activatecrew();

       mode = "speed-with-throttle";

       throttle = constant.TRUE;
   }


   # feedback
   me.holdthrottle( throttle );

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
   var id = "";


   # TEMPORARY work around for 2.0.0
   if( me.route_active() ) {
       # each time, because the route can change
       var wp = me.dependency["route"].getChildren("wp");
       var nb_wp = size(wp);

       # route manager doesn't update these fields
       if( nb_wp >= 1 ) {
           id = wp[0].getChild("id").getValue();
       }
   }

   me.dependency["waypoint"][0].getChild("id").setValue( id );


   me.context();

   me.waypointtoggle = me.itself["root-ctrl"].getChild("fg-waypoint").getValue();
   me.followswaypoint = me.itself["root-ctrl"].getChild("waypoint").getValue();
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
   if( me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.set_running();

       me.rates = me.speed_ratesec( me.rates );
       settimer( func { me.schedule(); }, me.rates );
   }
}

VirtualCopilot.supervisor = func {
   me.rates = me.COPILOTSEC;

   if( me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.set_activ();

       me.nightlighting.copilot( me );
       
       me.landinglights();
       if( me.dependency["crew-ctrl"].getChild("captain-busy").getValue() ) {
           me.taxilight();
       }

       me.rates = me.randoms( me.rates );
       me.timestamp();
   }

   me.itself["root"].getChild("activ").setValue(me.is_activ());
}

VirtualCopilot.landinglights = func {
   var targetstate = constant.FALSE;
   var thelights = me.dependency["lighting"].getChildren("landing");
               
   for( var i = 0; i < 2; i = i+1 ) {
        targetstate = me.dependency["crew-ctrl"].getChild("landing-lights").getValue();
        
        # retraction in flight
        if( me.noinstrument["airspeed"].getValue() > constantaero.LANDINGLIGHTKT ) {
            targetstate = constant.FALSE;
        }
        
        if( thelights[i].getChild("extend").getValue() != targetstate ) {
            if( me.can() ) {
                thelights[i].getChild("extend").setValue( targetstate );
                me.toggleclick("landing-extend-" ~ i);
            }
        }
        if( thelights[i].getChild("on").getValue() != targetstate ) {
            if( me.can() ) {
                thelights[i].getChild("on").setValue( targetstate );
                me.toggleclick("landing-on-" ~ i);
            }
        }
   }
}

VirtualCopilot.taxilight = func {
   var targetstate = me.dependency["crew-ctrl"].getChild("taxi-light").getValue();
   var thelight = me.dependency["lighting"].getNode("taxi");

   # off in flight
   if( me.noinstrument["airspeed"].getValue() > constantaero.LANDINGLIGHTKT ) {
       targetstate = constant.FALSE;
   }
   
   if( targetstate and thelight.getChild("passing").getValue() ) {
       if( me.can() ) {
           thelight.getChild("passing").setValue( constant.FALSE );
           me.toggleclick("taxi-passing");
       }
   }
   if( thelight.getChild("on").getValue() != targetstate ) {
       if( me.can() ) {
           thelight.getChild("on").setValue( targetstate );
           me.toggleclick("taxi-passing");
       }
   }
}

VirtualCopilot.followplan = func {
   # autopilot is already on
   if( me.headingmode == "dg-heading-hold" ) {
       if( me.waypointexist ) {
           # waypoint input toggles virtual copilot, which follows waypoint.
           if( !me.itself["root-ctrl"].getChild("activ").getValue() ) {
               if( me.waypointtoggle and me.followswaypoint ) {
                   me.activatecrew();
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
           me.activatecrew();
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
                     me.dependency["route-manager"].getChild("input").setValue("@DELETE0");
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

VirtualCopilot.activatecrew = func {
   if( !me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.toggleexport();
       me.engineercrew.toggleexport();
       me.crewscreen.toggleexport();
   }
}

VirtualCopilot.holdheading = func {
   # keep the current heading
   if( me.headingmode == "true-heading-hold" ) {
       me.autopilotsystem.real();
   }
}

VirtualCopilot.holdthrottle = func( throttle ) {
   if( throttle ) {
       me.log("throttle");
   }
   else {
       me.log("no-throttle");
   }

   me.itself["root"].getChild("throttle").setValue(throttle);
   me.itself["root"].getChild("state").setValue(me.state);
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

   if( me.route_active() ) {
       var ident = me.dependency["waypoint"][0].getChild("id").getValue();

       if( ident != nil ) {
           if( ident != "" ) {
               result = constant.TRUE;
           }
       }
   }

   return result;
}

VirtualCopilot.route_active = func {
   var result = constant.FALSE;

   # autopilot/route-manager/wp is updated only once airborne
   if( me.dependency["route-manager"].getChild("active").getValue() and
       me.dependency["route-manager"].getChild("airborne").getValue() ) {
       result = constant.TRUE;
   }

   return result;
}

VirtualCopilot.is_autothrottle = func {
   var result = constant.FALSE;

   if( me.dependency["autopilot"].getChild("speed").getValue() == "speed-with-throttle" ) {
       result = constant.TRUE;
   }

   return result;
}

VirtualCopilot.context = func {
   me.state = "";
}
