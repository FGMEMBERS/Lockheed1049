# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron


# current nasal version doesn't accept :
# - too many operations on 1 line.
# - variable with hyphen (?).



# ==============
# Initialization
# ==============

LockheedMain = {};

LockheedMain.new = func {
   obj = { parents : [LockheedMain]
         };

   obj.init();

   return obj;
}

LockheedMain.putinrelation = func {
   copilotcrew.set_relation( autopilotsystem );
}

# 1 s cron
LockheedMain.sec1cron = func {
   daytimeinstrument.schedule();

   # schedule the next call
   settimer(func{ me.sec1cron(); },daytimeinstrument.SPEEDUPSEC);
}

# 2 s cron
LockheedMain.sec2cron = func {
   fuelsystem.schedule();
   autopilotsystem.schedule();

   # schedule the next call
   settimer(func{ me.sec2cron(); },autopilotsystem.AUTOPILOTSEC);
}

# 3 s cron
LockheedMain.sec3cron = func {
   copilotcrew.schedule();

   # schedule the next call
   settimer(func{ me.sec3cron(); },copilotcrew.COPILOTSEC);
}

# 15 s cron
LockheedMain.sec15cron = func {
   copilotcrew.slowschedule();

   # schedule the next call
   settimer(func{ me.sec15cron(); },copilotcrew.CRUISESEC);
}

LockheedMain.savedata = func {
   aircraft.data.add("/controls/seat/recover");
   aircraft.data.add("/sim/presets/fuel");
   aircraft.data.add("/systems/seat/position/gear-well/x-m");
   aircraft.data.add("/systems/seat/position/gear-well/y-m");
   aircraft.data.add("/systems/seat/position/gear-well/z-m");
   aircraft.data.add("/systems/seat/position/observer/x-m");
   aircraft.data.add("/systems/seat/position/observer/y-m");
   aircraft.data.add("/systems/seat/position/observer/z-m");
}

# global variables in Lockheed1049 namespace, for call by XML
LockheedMain.instantiate = func {
   globals.Lockheed1049.constant = Constant.new();
   globals.Lockheed1049.fuelsystem = Fuel.new();
   globals.Lockheed1049.autopilotsystem = Autopilot.new();

   globals.Lockheed1049.daytimeinstrument = DayTime.new();

   globals.Lockheed1049.doorsystem = Doors.new();
   globals.Lockheed1049.seatsystem = Seats.new();
   globals.Lockheed1049.menusystem = Menu.new();

   globals.Lockheed1049.copilotcrew = VirtualCopilot.new();
}

LockheedMain.init = func {
   me.instantiate();
   me.putinrelation();

   # schedule the 1st call
   settimer(func { me.sec1cron(); },0);
   settimer(func { me.sec2cron(); },0);
   settimer(func { me.sec3cron(); },0);
   settimer(func { me.sec15cron(); },0);

   # saved on exit, restored at launch
   me.savedata();
}


L1049L = setlistener("/sim/signals/fdm-initialized", func { theconstellation = LockheedMain.new(); removelistener(L1049L); } );
#theconstellation = LockheedMain.new();
