# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ============
# VIRTUAL CREW
# ============

VirtualCrew = {};

VirtualCrew.new = func {
   var obj = { parents : [VirtualCrew,System], 

               generic : Generic.new(),

               GROUNDSEC : 15.0,                               # to reach the ground
               CREWSEC : 10.0,                                 # to complete the task
               TASKSEC : 2.0,                                  # between 2 tasks
               DELAYSEC : 1.0,                                 # random delay

               task : constant.FALSE,
               taskend : constant.TRUE,
               taskground : constant.FALSE,
               taskcrew : constant.FALSE,

               activ : constant.FALSE,
               running : constant.FALSE,

               state : ""
         };

    return obj;
}

VirtualCrew.inherit_virtualcrew = func( path ) {
    me.inherit_system( path );

    var obj = VirtualCrew.new();

    me.generic = obj.generic;

    me.GROUNDSEC = obj.GROUNDSEC;
    me.CREWSEC = obj.CREWSEC;
    me.TASKSEC = obj.TASKSEC;
    me.DELAYSEC = obj.DELAYSEC;

    me.task = obj.task;
    me.taskend = obj.taskend;
    me.taskground = obj.taskground;
    me.taskcrew = obj.taskcrew;

    me.activ = obj.activ;
    me.running = obj.running;
    me.state = obj.state;
}

VirtualCrew.toggleclick = func( message = "" ) {
    me.done( message );

    me.generic.toggleclick();
}

VirtualCrew.done = func( message = "" ) {
    if( message != "" ) {
        me.log( message );
    }

    # first task to do.
    me.task = constant.TRUE;
}

VirtualCrew.done_ground = func( message = "" ) {
    # procedure to execute with delay
    me.taskground = constant.TRUE;

    me.done( message );
}

VirtualCrew.done_crew = func( message = "" ) {
    # procedure to execute with delay
    me.taskcrew = constant.TRUE;

    me.done( message );
}

VirtualCrew.log = func( message ) {
    me.state = me.state ~ " " ~ message;
}

VirtualCrew.getlog = func {
    return me.state;
}

VirtualCrew.reset = func {
    me.state = "";
    me.activ = constant.FALSE;
    me.running = constant.FALSE;

    me.task = constant.FALSE;
    me.taskend = constant.TRUE;
}

VirtualCrew.set_activ = func {
    me.activ = constant.TRUE;
}

VirtualCrew.is_activ = func {
    return me.activ;
}

VirtualCrew.set_running = func {
    me.running = constant.TRUE;
}

VirtualCrew.is_running = func {
    return me.running;
}

VirtualCrew.wait_ground = func {
    return me.taskground;
}

VirtualCrew.reset_ground = func {
    me.taskground = constant.FALSE;
}

VirtualCrew.wait_crew = func {
    return me.taskcrew;
}

VirtualCrew.reset_crew = func {
    me.taskcrew = constant.FALSE;
}

VirtualCrew.can = func {
    # still something to do, must wait.
    if( me.task ) {
        me.taskend = constant.FALSE;
    }

    return !me.task;
}

VirtualCrew.randoms = func( steps ) {
    # doesn't overwrite, if no task to do
    if( !me.taskend ) {
        var margins  = rand() * me.DELAYSEC;

        if( me.taskground ) {
            steps = me.GROUNDSEC;
        }

        elsif( me.taskcrew ) {
            steps = me.CREWSEC;
        }

        else {
            steps = me.TASKSEC;
        }

        steps = steps + margins;
    }

    return steps;
} 

VirtualCrew.timestamp = func {
    var action = me.itself["root"].getChild("state").getValue();

    # save last real action
    if( action != "" ) {
        me.itself["root"].getChild("state-last").setValue(action);
    }

    me.itself["root"].getChild("state").setValue(me.getlog());
    me.itself["root"].getChild("time").setValue(me.noinstrument["time"].getChild("gmt-string").getValue());
}

VirtualCrew.completed = func {
    if( me.can() ) {
        me.set_completed();
    }
}

VirtualCrew.has_completed = func {
    var result = constant.FALSE;

    if( me.can() ) {
        result = me.is_completed();
    }

    return result;
}


# ==============
# NIGHT LIGHTING
# ==============

Nightlighting = {};

Nightlighting.new = func {
   var obj = { parents : [Nightlighting,System],

               DAYNORM : 0.0,
   
               defaultlevel : 0.0,
               lightlevel : 0.0,
               lightlow : constant.FALSE,

               NIGHTRAD : 1.57,                        # sun below horizon

               completed : constant.TRUE,
               night : constant.FALSE
         };

  obj.init();

  return obj;
}

Nightlighting.init = func {
    me.inherit_system("/systems/human");
}

Nightlighting.pilotexport = func {
    var value = me.itself["lighting"].getChild("pilot").getValue();

    me.dependency["lighting-pilot"].getChild("panel").setValue( value );
}

Nightlighting.copilotexport = func {
    var value = me.itself["lighting"].getChild("copilot").getValue();

    me.dependency["lighting-copilot"].getChild("panel").setValue( value );
}

Nightlighting.engineerexport = func {
    var value = me.itself["lighting"].getChild("engineer").getValue();

    me.dependency["lighting-engineer"].getChild("flood").setValue( value );
}

Nightlighting.copilot = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("night-lighting").getValue() ) {

       # only once, can be customized by user
       if( me.has_task() ) {
           me.light( "copilot" );

           me.set_task();

           # panel
           if( task.can() ) {
               if( me.dependency["lighting-copilot"].getChild("panel").getValue() != me.lightlevel ) {
                   me.dependency["lighting-copilot"].getChild("panel").setValue( me.lightlevel );
                   task.toggleclick("panel-light");
               }
           }
 
           # side
           if( task.can() ) {
               if( me.dependency["lighting-copilot"].getChild("side").getValue() != me.defaultlevel ) {
                   me.dependency["lighting-copilot"].getChild("side").setValue( me.defaultlevel );
                   task.toggleclick("side-level");
               }
           }

           if( task.can() ) {
               if( me.dependency["lighting-copilot"].getChild("side-on").getValue() != me.lightlow ) {
                   me.dependency["lighting-copilot"].getChild("side-on").setValue( me.lightlow );
                   task.toggleclick("side-light");
               }
           }

           # compass
           if( task.can() ) {
               if( me.dependency["lighting-copilot"].getChild("compass").getValue() != me.lightlevel ) {
                   me.dependency["lighting-copilot"].getChild("compass").setValue( me.lightlevel );
                   task.toggleclick("compass-light");
               }
           }

           # overhead
           if( task.can() ) {
               if( me.dependency["lighting-overhead"].getChild("panel").getValue() != me.lightlevel ) {
                   me.dependency["lighting-overhead"].getChild("panel").setValue( me.lightlevel );
                   task.toggleclick("overhead-light");
               }
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

Nightlighting.pilot = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("night-lighting").getValue() ) {

       # only once, can be customized by user
       if( me.has_task() ) {
           me.light( "pilot" );

           me.set_task();

           # panel
           if( task.can() ) {
               if( me.dependency["lighting-pilot"].getChild("panel").getValue() != me.lightlevel ) {
                   me.dependency["lighting-pilot"].getChild("panel").setValue( me.lightlevel );
                   task.toggleclick("panel-light");
               }
           }
 
           # side
           if( task.can() ) {
               if( me.dependency["lighting-pilot"].getChild("side").getValue() != me.defaultlevel ) {
                   me.dependency["lighting-pilot"].getChild("side").setValue( me.defaultlevel );
                   task.toggleclick("side-level");
               }
           }

           if( task.can() ) {
               if( me.dependency["lighting-pilot"].getChild("side-on").getValue() != me.lightlow ) {
                   me.dependency["lighting-pilot"].getChild("side-on").setValue( me.lightlow );
                   task.toggleclick("side-light");
               }
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

Nightlighting.engineer = func( task ) {
   # optional
   if( me.dependency["crew"].getChild("night-lighting").getValue() ) {

       # only once, can be customized by user
       if( me.has_task() ) {
           me.light( "engineer" );

           me.set_task();

           # panel
           if( task.can() ) {
               if( me.dependency["lighting-engineer"].getChild("flood").getValue() != me.lightlevel ) {
                   me.dependency["lighting-engineer"].getChild("flood").setValue( me.lightlevel );
                   task.toggleclick("flood-light");
               }
           }

           if( task.can() ) {
               me.set_completed();
           }
       }
   }
}

Nightlighting.light = func( path ) {
   me.defaultlevel = me.itself["lighting"].getChild(path).getValue();

   if( me.night ) {
       me.lightlevel = me.itself["lighting"].getChild(path).getValue();
       me.lightlow = constant.TRUE;
   }
   else {
       me.lightlevel = me.DAYNORM;
       me.lightlow = constant.FALSE;
   }
}

Nightlighting.is_change = func {
   var change = constant.FALSE;

   if( me.is_night() ) {
       if( !me.night ) {
           me.night = constant.TRUE;
           change = constant.TRUE;
       }
   }
   else {
       if( me.night ) {
           me.night = constant.FALSE;
           change = constant.TRUE;
       }
   }

   return change;
}

Nightlighting.is_night = func {
   var result = constant.FALSE;

   if( me.noinstrument["sun"].getValue() > me.NIGHTRAD ) {
       result = constant.TRUE;
   }

   return result;
}

# once night lighting, virtual crew must switch again lights.
Nightlighting.set_task = func {
   me.completed = constant.FALSE;
}

Nightlighting.has_task = func {
   var result = constant.FALSE;

   if( me.is_change() or !me.completed ) {
       result = constant.TRUE;
   }
   else {
       result = constant.FALSE;
   }

   return result;
}

Nightlighting.set_completed = func {
   me.completed = constant.TRUE;
}
