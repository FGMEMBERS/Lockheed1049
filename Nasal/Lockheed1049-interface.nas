# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# SEATS
# =====

Seats = {};

Seats.new = func {
   obj = { parents : [Seats],

           controls : nil,
           positions : nil,
           theseats : nil,

           lookup : { "engineer" : 0, "radio" : 0, "copilot" : 0, "navigator" : 0, "observer" : 0,
                      "gear-well" : 0 },
           names : [ "engineer", "radio", "copilot", "navigator", "observer", "gear-well" ],
           nb_seats : 6,

           firstseat : constant.FALSE,
           firstseatview : 0,               
           fullcokpit : constant.FALSE,   

           recoverfloating : constant.FALSE,
           last_recover : { "gear-well" : constant.FALSE, "observer" : constant.FALSE },
           initial : { "gear-well" : { "x" : 0, "y" : 0, "z" : 0 },
                       "observer" : {"x" : 0, "y" : 0, "z" : 0 } }
         };

   obj.init();

   return obj;
};

Seats.init = func {
   me.controls = props.globals.getNode("/controls/seat");
   me.positions = props.globals.getNode("/systems/seat/position");
   me.theseats = props.globals.getNode("/systems/seat");

   theviews = props.globals.getNode("/sim").getChildren("view");
   last = size(theviews);

   # retrieve the index as created by FG
   for( i = 0; i < last; i=i+1 ) {
        child = theviews[i].getChild("name");

        # nasal doesn't see yet the views of preferences.xml
        if( child != nil ) {
            name = child.getValue();
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
           elsif( name == "Observer View" ) {
                me.lookup["observer"] = i;
                me.save_initial( "observer", theviews[i] );
           }
           elsif( name == "Gear Well View" ) {
                me.lookup["gear-well"] = i;
                me.save_initial( "gear-well", theviews[i] );
           }

           if( !me.firstseat ) {
                me.firstseatview = i;
                me.firstseat = constant.TRUE;
           }
        }
   }

   # default
   me.recoverfloating = me.controls.getChild("recover").getValue();
   me.fullcockpit = me.controls.getChild("all").getValue();
}

Seats.recoverexport = func {
   me.recoverfloating = !me.recoverfloating;
   me.controls.getChild("recover").setValue(me.recoverfloating);
}

Seats.fullexport = func {
   if( me.fullcockpit ) {
       me.fullcockpit = constant.FALSE;
   }
   else {
       me.fullcockpit = constant.TRUE;
   }

   me.controls.getChild("all").setValue( me.fullcockpit );
}

Seats.viewexport = func( name ) {
   if( name != "captain" ) {

       # swap to view
       if( !me.theseats.getChild(name).getValue() ) {
           index = me.lookup[name];
           setprop("/sim/current-view/view-number", index);
           me.theseats.getChild(name).setValue(constant.TRUE);
           me.theseats.getChild("captain").setValue(constant.FALSE);
       }

       # return to captain view
       else {
           setprop("/sim/current-view/view-number", 0);
           me.theseats.getChild(name).setValue(constant.FALSE);
           me.theseats.getChild("captain").setValue(constant.TRUE);
       }

       # disable all other views
       for( i = 0; i < me.nb_seats; i=i+1 ) {
            if( name != me.names[i] ) {
                me.theseats.getChild(me.names[i]).setValue(constant.FALSE);
            }
       }

       me.recover();
   }

   # captain view
   else {
       setprop("/sim/current-view/view-number",0);
       me.theseats.getChild("captain").setValue(constant.TRUE);

        # disable all other views
        for( i = 0; i < me.nb_seats; i=i+1 ) {
             me.theseats.getChild(me.names[i]).setValue(constant.FALSE);
        }
   }

   me.controls.getChild("all").setValue( me.fullcockpit );
}

Seats.scrollexport = func{
   # number of views = 11
   nbviews = getprop("/sim/number-views");

   # by default, returns to captain view
   targetview = nbviews;

   # if specific view, step once more to ignore captain view 
   for( i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
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

   me.restorefull();
}

Seats.scrollreverseexport = func{
   # number of views = 11
   nbviews = getprop("/sim/number-views");

   # by default, returns to captain view
   targetview = 0;

   # if specific view, step once more to ignore captain view 
   for( i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
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

   me.restorefull();
}

Seats.restorefull = func {
   found = constant.FALSE;
   index = getprop("/sim/current-view/view-number");
   if( index == 0 or index >= me.firstseatview ) {
       found = constant.TRUE;
   }

   # systematically disable all instruments in external view
   if( found ) {
       me.controls.getChild("all").setValue( me.fullcockpit );
   }
   else {
       me.controls.getChild("all").setValue( constant.FALSE );
   }
}

# forwards is positiv
Seats.movelengthexport = func( step ) {
   if( me.move() ) {
       headdeg = getprop("/sim/current-view/goal-heading-offset-deg");

       if( headdeg <= 45 or headdeg >= 315 ) {
           prop = "/sim/current-view/z-offset-m";
           sign = 1;
       }
       elsif( headdeg >= 135 and headdeg <= 225 ) {
           prop = "/sim/current-view/z-offset-m";
           sign = -1;
       }
       elsif( headdeg > 225 and headdeg < 315 ) {
           prop = "/sim/current-view/x-offset-m";
           sign = -1;
       }
       else {
           prop = "/sim/current-view/x-offset-m";
           sign = 1;
       }

       pos = getprop(prop);
       pos = pos + sign * step;
       setprop(prop,pos);

       result = constant.TRUE;
   }

   else {
       result = constant.FALSE;
   }

   return result;
}

# left is negativ
Seats.movewidthexport = func( step ) {
   if( me.move() ) {
       headdeg = getprop("/sim/current-view/goal-heading-offset-deg");

       if( headdeg <= 45 or headdeg >= 315 ) {
           prop = "/sim/current-view/x-offset-m";
           sign = 1;
       }
       elsif( headdeg >= 135 and headdeg <= 225 ) {
           prop = "/sim/current-view/x-offset-m";
           sign = -1;
       }
       elsif( headdeg > 225 and headdeg < 315 ) {
           prop = "/sim/current-view/z-offset-m";
           sign = 1;
       }
       else {
           prop = "/sim/current-view/z-offset-m";
           sign = -1;
       }

       pos = getprop(prop);
       pos = pos + sign * step;
       setprop(prop,pos);

       result = constant.TRUE;
   }

   else {
       result = constant.FALSE;
   }

   return result;
}

# up is positiv
Seats.moveheightexport = func( step ) {
   if( me.move() ) {
       pos = getprop("/sim/current-view/y-offset-m");
       pos = pos + step;
       setprop("/sim/current-view/y-offset-m",pos);

       result = constant.TRUE;
   }

   else {
       result = constant.FALSE;
   }

   return result;
}

# backup initial position
Seats.save_initial = func( name, view ) {
   config = view.getNode("config");
   me.initial[name]["x"] = config.getChild("x-offset-m").getValue();
   me.initial[name]["y"] = config.getChild("y-offset-m").getValue();
   me.initial[name]["z"] = config.getChild("z-offset-m").getValue();
}

Seats.initial_position = func( name ) {
   position = me.positions.getNode(name);

   posx = me.initial[name]["x"];
   posy = me.initial[name]["y"];
   posz = me.initial[name]["z"];

   setprop("/sim/current-view/x-offset-m",posx);
   setprop("/sim/current-view/y-offset-m",posy);
   setprop("/sim/current-view/z-offset-m",posz);

   position.getChild("x-m").setValue(posx);
   position.getChild("y-m").setValue(posy);
   position.getChild("z-m").setValue(posz);
}

Seats.last_position = func( name ) {
   # 1st restore
   if( !me.last_recover[ name ] and me.recoverfloating ) {
       position = me.positions.getNode(name);

       posx = position.getChild("x-m").getValue();
       posy = position.getChild("y-m").getValue();
       posz = position.getChild("z-m").getValue();

       if( posx != me.initial[name]["x"] or
           posy != me.initial[name]["y"] or
           posz != me.initial[name]["z"] ) {

           setprop("/sim/current-view/x-offset-m",posx);
           setprop("/sim/current-view/y-offset-m",posy);
           setprop("/sim/current-view/z-offset-m",posz);
       }

       me.last_recover[ name ] = constant.TRUE;
   }
}

Seats.recover = func {
   if( me.theseats.getChild("gear-well").getValue() ) {
       me.last_position( "gear-well" );
   }
   elsif( me.theseats.getChild("observer").getValue() ) {
       me.last_position( "observer" );
   }
}

Seats.move_position = func( name ) {
   posx = getprop("/sim/current-view/x-offset-m");
   posy = getprop("/sim/current-view/y-offset-m");
   posz = getprop("/sim/current-view/z-offset-m");

   position = me.positions.getNode(name);

   position.getChild("x-m").setValue(posx);
   position.getChild("y-m").setValue(posy);
   position.getChild("z-m").setValue(posz);
}

Seats.move = func {
   # saves previous position
   if( me.theseats.getChild("gear-well").getValue() ) {
       me.move_position("gear-well");
       result = constant.TRUE;
   }
   elsif( me.theseats.getChild("observer").getValue() ) {
       me.move_position("observer");
       result = constant.TRUE;
   }
   else {
       result = constant.FALSE;
   }

   return result;
}

# restore view
Seats.restoreexport = func {
   if( me.theseats.getChild("observer").getValue() ) {
       me.initial_position( "observer" );
   }
   elsif( me.theseats.getChild("gear-well").getValue() ) {
       me.initial_position( "gear-well" );
   }
}


# =====
# DOORS
# =====

Doors = {};

Doors.new = func {
   obj = { parents : [Doors],
           crew : aircraft.door.new("instrumentation/doors/crew", 10.0),
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


# ====
# MENU
# ====

Menu = {};

Menu.new = func {
   obj = { parents : [Menu],

           crew : nil,
           fuel : nil,
           radios : nil,
           menu : nil
         };

   obj.init();

   return obj;
};

Menu.init = func {
   me.menu = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/menu/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-menu.xml");
   me.crew = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/crew/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-crew.xml");
   me.fuel = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/fuel/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-fuel.xml");
   me.radios = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/radios/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-radios.xml");
}
