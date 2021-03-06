# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron


# current nasal version doesn't accept :
# - too many operations on 1 line.
# - variable with hyphen (?).



# =================
# OVERRIDING JSBSIM
# =================

LockheedJSBsim = {};

LockheedJSBsim.new = func {
   var obj = { parents : [LockheedJSBsim]
         };

   obj.init();

   return obj;
}

LockheedJSBsim.init = func {
}

LockheedJSBsim.specific = func {
   # fix JSBSim bug
#   setprop( "controls/flight/elevator-boost", constant.TRUE );

   # disable JSBSim stand alone mode
   setprop( "fdm/jsbsim/propulsion/tank[0]/priority", 0 );
   setprop( "fdm/jsbsim/propulsion/tank[1]/priority", 0 );
   setprop( "fdm/jsbsim/propulsion/tank[2]/priority", 0 );
   setprop( "fdm/jsbsim/propulsion/tank[3]/priority", 0 );
}


# ==============
# Initialization
# ==============

LockheedMain = {};

LockheedMain.new = func {
   var obj = { parents : [LockheedMain]
         };

   obj.init();

   return obj;
}

LockheedMain.putinrelation = func {
   copilotcrew.set_relation( autopilotsystem, crewscreen, engineercrew );
}

# 1 s cron
LockheedMain.sec1cron = func {
   fuelsystem.schedule();
   lightingsystem.schedule();
   enginesystem.schedule();
   terraininstrument.schedule();
   daytimeinstrument.schedule();

   # schedule the next call
   settimer(func{ me.sec1cron(); },daytimeinstrument.SPEEDUPSEC);
}

# 2 s cron
LockheedMain.sec2cron = func {
   gearsystem.schedule();
   doorsystem.schedule();
   copilotcrew.fastschedule();

   # schedule the next call
   settimer(func{ me.sec2cron(); },copilotcrew.COPILOTSEC);
}

# 3 s cron
LockheedMain.sec3cron = func {
   autopilotsystem.schedule();
   crewscreen.schedule();

   # schedule the next call
   settimer(func{ me.sec3cron(); },crewscreen.MENUSEC);
}

LockheedMain.savedata = func {
   var saved_props = [ "/controls/copilot/fg-autopilot",
                       "/controls/copilot/fg-waypoint",
                       "/controls/crew/captain-busy",
                       "/controls/crew/landing-lights",
                       "/controls/crew/night-lighting",
                       "/controls/crew/lighting/chart",
                       "/controls/crew/lighting/overhead",
                       "/controls/crew/lighting/pedestal",
                       "/controls/crew/taxi-light",
                       "/controls/crew/timeout",
                       "/controls/crew/timeout-s",
                       "/controls/doors/flight-station/opened",
                       "/controls/environment/rembrandt/cockpit",
                       "/controls/environment/rembrandt/external",
                       "/controls/environment/rembrandt/landing",
                       "/controls/environment/rembrandt/panel",
                       "/controls/environment/smoke",
                       "/controls/fuel/reinit",
                       "/controls/human/lighting/copilot",
                       "/controls/human/lighting/engineer",
                       "/controls/human/lighting/instrument",
                       "/controls/human/lighting/overhead",
                       "/controls/human/lighting/pilot",
                       "/controls/seat/recover",
                       "/sim/model/immat",
                       "/systems/fuel/presets",
                       "/systems/seat/offset/captain",
                       "/systems/seat/offset/engineer",
                       "/systems/seat/position/gear-well/x-m",
                       "/systems/seat/position/gear-well/y-m",
                       "/systems/seat/position/gear-well/z-m",
                       "/systems/seat/position/observer/x-m",
                       "/systems/seat/position/observer/y-m",
                       "/systems/seat/position/observer/z-m",
                       "/systems/seat/position/observer2/x-m",
                       "/systems/seat/position/observer2/y-m",
                       "/systems/seat/position/observer2/z-m" ];

   for( var i = 0; i < size(saved_props); i = i + 1 ) {
        aircraft.data.add(saved_props[i]);
   }
}

# global variables in Lockheed1049 namespace, for call by XML
LockheedMain.instantiate = func {
   globals.Lockheed1049.constant = Constant.new();
   globals.Lockheed1049.constantaero = ConstantAero.new();

   globals.Lockheed1049.lightingsystem = Lighting.new();
   globals.Lockheed1049.fuelsystem = Fuel.new();
   globals.Lockheed1049.gearsystem = Gear.new();
   globals.Lockheed1049.enginesystem = Engine.new();
   globals.Lockheed1049.autopilotsystem = Autopilot.new();

   globals.Lockheed1049.terraininstrument = TerrainWarning.new();
   globals.Lockheed1049.daytimeinstrument = Daytime.new();

   globals.Lockheed1049.doorsystem = Doors.new();
   globals.Lockheed1049.seatsystem = Seats.new();

   globals.Lockheed1049.menuscreen = Menu.new();
   globals.Lockheed1049.crewscreen = Crewbox.new();

   globals.Lockheed1049.copilotcrew = VirtualCopilot.new();
   globals.Lockheed1049.engineercrew = VirtualEngineer.new();
}

LockheedMain.init = func {
   aircraft.livery.init("Aircraft/Lockheed1049/Models/Liveries",
                        "sim/model/livery/name",
                        "sim/model/livery/index");

   me.instantiate();
   me.putinrelation();

   # JSBSim specific
   var FDM = LockheedJSBsim.new();
   FDM.specific();

   # schedule the 1st call
   settimer(func { me.sec1cron(); },0);
   settimer(func { me.sec2cron(); },0);
   settimer(func { me.sec3cron(); },0);

   # saved on exit, restored at launch
   me.savedata();
}

# state reset
LockheedMain.reinit = func {
   if( getprop("/controls/fuel/reinit") ) {
       # default is JSBSim state, which loses fuel selection.
       globals.Lockheed1049.fuelsystem.reinitexport();
   }
}


# object creation
L1049L = setlistener("/sim/signals/fdm-initialized", func { globals.Lockheed1049.main = LockheedMain.new(); removelistener(L1049L); } );

# state reset
L1049L2 = setlistener("/sim/signals/reinit", func { globals.Lockheed1049.main.reinit(); });
