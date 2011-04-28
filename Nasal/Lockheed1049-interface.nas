# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# SEATS
# =====

Seats = {};

Seats.new = func {
   var obj = { parents : [Seats],

               controls : nil,
               positions : nil,
               theseats : nil,
               theviews : nil,

               lookup : {},
               names : {},
               nb_seats : 0,

               CAPTINDEX : 0,

               firstseat : constant.FALSE,
               firstseatview : 0,               
               fullcokpit : constant.FALSE,   
               fulloutside : constant.FALSE,

               floating : {},
               recoverfloating : constant.FALSE,
               last_recover : {},
               initial : {}
         };

   obj.init();

   return obj;
};

Seats.init = func {
   var child = nil;
   var name = "";

   me.controls = props.globals.getNode("/controls/seat");
   me.positions = props.globals.getNode("/systems/seat/position");
   me.theseats = props.globals.getNode("/systems/seat");
   me.theviews = props.globals.getNode("/sim").getChildren("view");

   # retrieve the index as created by FG
   for( var i = 0; i < size(me.theviews); i=i+1 ) {
        child = me.theviews[i].getChild("name");

        # nasal doesn't see yet the views of preferences.xml
        if( child != nil ) {
            name = child.getValue();
            if( name == "Engineer View" ) {
                me.save_lookup("engineer", i);
            }
            elsif( name == "Radio View" ) {
                me.save_lookup("radio", i);
            }
            elsif( name == "Copilot View" ) {
                me.save_lookup("copilot", i);
            }
            elsif( name == "Navigator View" ) {
                 me.save_lookup("navigator", i);
            }
            elsif( name == "Observer View" ) {
                 me.save_lookup("observer", i);
                 me.save_initial( "observer", me.theviews[i] );
            }
            elsif( name == "Observer 2 View" ) {
                 me.save_lookup("observer2", i);
                 me.save_initial( "observer2", me.theviews[i] );
            }
            elsif( name == "Gear Well View" ) {
                 me.save_lookup("gear-well", i);
                 me.save_initial( "gear-well", me.theviews[i] );
            }
        }
   }

   # default
   me.recoverfloating = me.controls.getChild("recover").getValue();
   me.fullcockpit = me.controls.getChild("all").getValue();
   me.fulloutside = me.controls.getChild("all-outside").getValue();
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

Seats.fulloutsideexport = func {
   if( me.fulloutside ) {
       me.fulloutside = constant.FALSE;
   }
   else {
       me.fulloutside = constant.TRUE;
   }

   me.controls.getChild("all-outside").setValue( me.fulloutside );
}

Seats.viewexport = func( name ) {
   var index = 0;

   if( name != "captain" ) {
       index = me.lookup[name];

       # swap to view
       if( !me.theseats.getChild(name).getValue() ) {
           setprop("/sim/current-view/view-number", index);
           me.theseats.getChild(name).setValue(constant.TRUE);
           me.theseats.getChild("captain").setValue(constant.FALSE);

           me.theviews[index].getChild("enabled").setValue(constant.TRUE);
       }

       # return to captain view
       else {
           setprop("/sim/current-view/view-number", 0);
           me.theseats.getChild(name).setValue(constant.FALSE);
           me.theseats.getChild("captain").setValue(constant.TRUE);

           me.theviews[index].getChild("enabled").setValue(constant.FALSE);
       }

       # disable all other views
       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            if( name != me.names[i] ) {
                me.theseats.getChild(me.names[i]).setValue(constant.FALSE);

                index = me.lookup[me.names[i]];
                me.theviews[index].getChild("enabled").setValue(constant.FALSE);
            }
       }

       me.recover();
   }

   # captain view
   else {
       setprop("/sim/current-view/view-number",0);
       me.theseats.getChild("captain").setValue(constant.TRUE);

       # disable all other views
       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            me.theseats.getChild(me.names[i]).setValue(constant.FALSE);

            index = me.lookup[me.names[i]];
            me.theviews[index].getChild("enabled").setValue(constant.FALSE);
       }
   }

   me.controls.getChild("all").setValue( me.fullcockpit );
   me.controls.getChild("all-outside").setValue( constant.FALSE );
}

Seats.scrollexport = func{
   me.stepView(1);
}

Seats.scrollreverseexport = func{
   me.stepView(-1);
}

Seats.stepView = func( step ) {
   var targetview = 0;
   var name = "";

   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            targetview = me.lookup[name];
            break;
        }
   }

   # ignores captain view
   if( targetview > me.CAPTINDEX ) {
       me.theviews[me.CAPTINDEX].getChild("enabled").setValue(constant.FALSE);
   }

   view.stepView(step);

   # restores of userarchive
   if( targetview > me.CAPTINDEX ) {
       me.theviews[me.CAPTINDEX].getChild("enabled").setValue(constant.TRUE);
   }

   me.restorefull();
}

# forwards is positiv
Seats.movelengthexport = func( step ) {
   var sign = 0;
   var headdeg = 0.0;
   var pos = 0.0;
   var result = constant.FALSE;
   var prop = "";

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

   return result;
}

# left is negativ
Seats.movewidthexport = func( step ) {
   var sign = 0;
   var headdeg = 0.0;
   var pos = 0.0;
   var result = constant.FALSE;
   var prop = "";

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

   return result;
}

# up is positiv
Seats.moveheightexport = func( step ) {
   var pos = 0.0;
   var result = constant.FALSE;

   if( me.move() ) {
       pos = getprop("/sim/current-view/y-offset-m");
       pos = pos + step;
       setprop("/sim/current-view/y-offset-m",pos);

       result = constant.TRUE;
   }

   return result;
}

Seats.save_lookup = func( name, index ) {
   me.names[me.nb_seats] = name;

   me.lookup[name] = index;

   if( !me.firstseat ) {
       me.firstseatview = index;
       me.firstseat = constant.TRUE;
   }

   me.floating[name] = constant.FALSE;

   me.nb_seats = me.nb_seats + 1;
}

Seats.restorefull = func {
   var found = constant.FALSE;
   var index = getprop("/sim/current-view/view-number");

   if( index == me.CAPTINDEX or index >= me.firstseatview ) {
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

# backup initial position
Seats.save_initial = func( name, view ) {
   var pos = {};
   var config = view.getNode("config");

   pos["x"] = config.getChild("x-offset-m").getValue();
   pos["y"] = config.getChild("y-offset-m").getValue();
   pos["z"] = config.getChild("z-offset-m").getValue();

   me.initial[name] = pos;

   me.floating[name] = constant.TRUE;
   me.last_recover[name] = constant.FALSE;
}

Seats.initial_position = func( name ) {
   var position = me.positions.getNode(name);

   var posx = me.initial[name]["x"];
   var posy = me.initial[name]["y"];
   var posz = me.initial[name]["z"];

   setprop("/sim/current-view/x-offset-m",posx);
   setprop("/sim/current-view/y-offset-m",posy);
   setprop("/sim/current-view/z-offset-m",posz);

   position.getChild("x-m").setValue(posx);
   position.getChild("y-m").setValue(posy);
   position.getChild("z-m").setValue(posz);
}

Seats.last_position = func( name ) {
   var position = nil;
   var posx = 0.0;
   var posy = 0.0;
   var posz = 0.0;
   
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
   var name = "";

   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.last_position( name );
            }
            break;
        }
   }
}

Seats.move_position = func( name ) {
   var posx = getprop("/sim/current-view/x-offset-m");
   var posy = getprop("/sim/current-view/y-offset-m");
   var posz = getprop("/sim/current-view/z-offset-m");

   var position = me.positions.getNode(name);

   position.getChild("x-m").setValue(posx);
   position.getChild("y-m").setValue(posy);
   position.getChild("z-m").setValue(posz);
}

Seats.move = func {
   var name = "";
   var result = constant.FALSE;

   # saves previous position
   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.move_position( name );
                result = constant.TRUE;
            }
            break;
        }
   }

   return result;
}

# restore view
Seats.restoreexport = func {
   var name = "";

   for( var i = 0; i < me.nb_seats; i=i+1 ) {
        name = me.names[i];
        if( me.theseats.getChild(name).getValue() ) {
            if( me.floating[name] ) {
                me.initial_position( name );
            }
            break;
        }
   }
}

# restore view pitch
Seats.restorepitchexport = func {
   var index = getprop("/sim/current-view/view-number");

   if( index == me.CAPTINDEX ) {
       var headingdeg = me.theviews[index].getNode("config").getChild("heading-offset-deg").getValue();
       var pitchdeg = me.theviews[index].getNode("config").getChild("pitch-offset-deg").getValue();

       setprop("/sim/current-view/heading-offset-deg", headingdeg );
       setprop("/sim/current-view/pitch-offset-deg", pitchdeg );
   }

   # only cockpit views
   else {
       var name = "";

       for( var i = 0; i < me.nb_seats; i=i+1 ) {
            name = me.names[i];
            if( me.theseats.getChild(name).getValue() ) {
                var headingdeg = me.theviews[index].getNode("config").getChild("heading-offset-deg").getValue();
                var pitchdeg = me.theviews[index].getNode("config").getChild("pitch-offset-deg").getValue();

                setprop("/sim/current-view/heading-offset-deg", headingdeg );
                setprop("/sim/current-view/pitch-offset-deg", pitchdeg );
                break;
            }
        }
   }
}


# ====
# MENU
# ====

Menu = {};

Menu.new = func {
   var obj = { parents : [Menu],

               autopilot : nil,
               crew : nil,
               fuel : nil,
               ground : nil,
               immat : nil,
               procedures : {},
               radios : nil,
               menu : nil
         };

   obj.init();

   return obj;
};

Menu.init = func {
   me.menu = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/menu/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-menu.xml");
   me.autopilot = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/autopilot/dialog",
                                 "Aircraft/Lockheed1049/Dialogs/Lockheed1049-autopilot.xml");
   me.crew = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/crew/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-crew.xml");
   me.fuel = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/fuel/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-fuel.xml");
   me.ground = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/ground/dialog",
                              "Aircraft/Lockheed1049/Dialogs/Lockheed1049-ground.xml");
   me.immat = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/immat/dialog",
                             "Aircraft/Lockheed1049/Dialogs/Lockheed1049-immat.xml");

   me.array( me.procedures, 2, "procedures" );

   me.radios = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/radios/dialog",
                            "Aircraft/Lockheed1049/Dialogs/Lockheed1049-radios.xml");
}

Menu.array = func( table, max, name ) {
    var j = 0;

    for( var i = 0; i < max; i=i+1 ) {
       if( j == 0 ) {
           j = "";
       }
       else {
           j = i + 1;
       }

       table[i] = gui.Dialog.new("/sim/gui/dialogs/Lockheed1049/" ~ name ~ "[" ~ i ~ "]/dialog",
                                 "Aircraft/Lockheed1049/Dialogs/Lockheed1049-" ~ name ~ j ~ ".xml");
    }
}


# ========
# CREW BOX
# ========

Crewbox = {};

Crewbox.new = func {
   var obj = { parents : [Crewbox],

               MENUSEC : 3.0,

               timers : 0.0,

               copilot : nil,
               copilotcontrol : nil,
               crew : nil,
               crewcontrols : nil,
               engineercontrol : nil,
               voice : nil,

# left bottom, 1 line, 10 seconds.
               BOXX : 10,
               BOXY : 34,
               BOTTOMY : -768,
               LINEY : 20,

               lineindex : { "speedup" : 0, "checklist" : 1, "engineer" : 2, "copilot" : 3 },
               lasttext : [ "", "", "", "" ],
               textbox : [ nil, nil, nil, nil ],
               nblines : 4
         };

    obj.init();

    return obj;
};

Crewbox.init = func {
    me.copilot = props.globals.getNode("/systems/copilot");
    me.copilotcontrol = props.globals.getNode("/controls/copilot");
    me.crew = props.globals.getNode("/systems/crew");
    me.crewcontrols = props.globals.getNode("/controls/crew");
    me.engineer = props.globals.getNode("/systems/engineer");
    me.engineercontrol = props.globals.getNode("/controls/engineer");
    me.voice = props.globals.getNode("/systems/voice");
 

    me.resize();

    setlistener("/sim/startup/ysize", crewboxresizecron);
    setlistener("/sim/speed-up", crewboxcron);
    setlistener("/sim/freeze/master", crewboxcron);
}

Crewbox.resize = func {
    var y = 0;
    var ysize = - getprop("/sim/startup/ysize");

    if( ysize == nil ) {
        ysize = me.BOTTOMY;
    }

    # must clear the text, otherwise text remains after close
    me.clear();

    for( var i = 0; i < me.nblines; i = i+1 ) {
         # starts at 700 if height is 768
         y = ysize + me.BOXY + me.LINEY * i;

         # not really deleted
         if( me.textbox[i] != nil ) {
             me.textbox[i].close();
         }

         # CAUTION : duration is 0 (infinite), or one must wait that the text vanishes device;
         # otherwise, overwriting the text makes the view popup tip always visible !!!
         me.textbox[i] = screen.window.new( me.BOXX, y, 1, 0 );
    }

    me.crewtext();
    me.pausetext();
}

Crewbox.pausetext = func {
    var index = me.lineindex["speedup"];
    var speedup = 0.0;
    var red = constant.FALSE;
    var text = "";

    if( getprop("/sim/freeze/master") ) {
        text = "pause";
    }
    else {
        speedup = getprop("/sim/speed-up");
        if( speedup > 1 ) {
            text = sprintf( speedup, "3f.0" ) ~ "  t";
        }
        red = constant.TRUE;
    }

    me.sendpause( index, red, text );
}

crewboxresizecron = func {
    crewscreen.resize();
}

crewboxcron = func {
    crewscreen.pausetext();
}

Crewbox.minimizeexport = func {
    var value = me.crew.getChild("minimized").getValue();

    me.crew.getChild("minimized").setValue(!value);

    me.resettimer();
}

Crewbox.toggleexport = func {
    # 2D feedback
    if( !getprop("/systems/human/serviceable") ) {
        me.crew.getChild("minimized").setValue(constant.FALSE);
        me.resettimer();
    }

    # to accelerate display
    me.crewtext();
}

Crewbox.schedule = func {
    # timeout on text box
    if( me.crewcontrols.getChild("timeout").getValue() ) {
        me.timers = me.timers + me.MENUSEC;
        if( me.timers >= me.timeoutsec() ) {
            me.crew.getChild("minimized").setValue(constant.TRUE);
        }
    }

    me.crewtext();
}

Crewbox.timeoutsec = func {
    var result = me.crewcontrols.getChild("timeout-s").getValue();

    if( result < me.MENUSEC ) {
        result = me.MENUSEC;
    }

    return result;
}

Crewbox.resettimer = func {
    me.timers = 0.0;

    me.crewtext();
}

Crewbox.crewtext = func {
    if( !me.crew.getChild("minimized").getValue() or
        !me.crewcontrols.getChild("timeout").getValue() ) {
        me.checklisttext();
        me.copilottext();
        me.engineertext();
    }
    else {
        me.clearcrew();
    }
}

Crewbox.checklisttext = func {
    var white = constant.FALSE;
    var text = me.voice.getChild("callout").getValue();
    var text2 = me.voice.getChild("checklist").getValue();
    var text = "";
    var text2 = "";
    var index = me.lineindex["checklist"];

    if( text2 != "" ) {
        text = text2 ~ " " ~ text;
        white = me.voice.getChild("real").getValue();
    }

    # real checklist is white
    me.sendtext( index, constant.TRUE, white, text );
}

Crewbox.copilottext = func {
    var green = constant.FALSE;
    var text = me.copilot.getChild("state").getValue();
    var index = me.lineindex["copilot"];

    if( text == "" ) {
        if( me.copilotcontrol.getChild("activ").getValue() ) {
            text = "copilot";
        }
    }

    if( me.copilot.getChild("activ").getValue() ) {
        green = constant.TRUE;
    }

    me.sendtext( index, green, constant.FALSE, text );
}

Crewbox.engineertext = func {
    var green = me.engineer.getChild("activ").getValue();
    var text = me.engineer.getChild("state").getValue();
    var index = me.lineindex["engineer"];

    if( text == "" ) {
        if( me.engineercontrol.getChild("activ").getValue() ) {
            text = "engineer";
        }
    }

    me.sendtext( index, green, constant.FALSE, text );
}

Crewbox.sendtext = func( index, green, white, text ) {
    var box = me.textbox[index];

    me.lasttext[index] = text;

    # bright white
    if( white ) {
        box.write( text, 1.0, 1.0, 1.0 );
    }

    # dark green
    elsif( green ) {
        box.write( text, 0, 0.7, 0 );
    }

    # dark yellow
    else {
        box.write( text, 0.7, 0.7, 0 );
    }
}

Crewbox.sendclear = func( index, text ) {
    var box = me.textbox[index];

    me.lasttext[index] = text;

    box.write( text, 0, 0, 0 );
}

Crewbox.sendpause = func( index, red, text ) {
    var box = me.textbox[index];

    me.lasttext[index] = text;

    # bright red
    if( red ) {
        box.write( text, 1.0, 0, 0 );
    }
    # bright yellow
    else {
        box.write( text, 1.0, 1.0, 0 );
    }
}

Crewbox.clearcrew = func {
    var standbytext = "";

    for( var i = 1; i < me.nblines; i = i+1 ) {
         if( me.lasttext[i] != standbytext ) {
             me.sendclear( i, standbytext );
         }
    }
}

Crewbox.clear = func {
    var standbytext = "";

    for( var i = 0; i < me.nblines; i = i+1 ) {
         if( me.lasttext[i] != standbytext ) {
             me.sendclear( i, standbytext );
         }
    }
}
