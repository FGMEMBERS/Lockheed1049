# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =========
# AUTOPILOT
# =========

Autopilot = {};

Autopilot.new = func {
   obj = { parents : [Autopilot],

           AUTOPILOTSEC : 2.0
         };

   obj.init();

   return obj;
};

Autopilot.init = func {
   # glows 35 to 45 times per minute
#   aircraft.light.new("/systems/autopilot/gyro-beacon", 0.03, 1.30 + rand()*0.38);
   aircraft.light.new("/systems/autopilot/gyro-beacon", [0.03, 1.30 + rand()*0.38]);
}

# autopilot hold
Autopilot.apexport = func {
    modev = getprop("/autopilot/locks/altitude");

    # if not altitude on
    if( modev != "altitude-hold" ) {
        modeh = getprop("/autopilot/locks/heading");
        if( modev != "pitch-hold" or ( modeh != "dg-heading-hold" and modeh != "true-heading-hold" ) ) {
            clutch = constant.TRUE;

            modev = "pitch-hold";
            pitchdeg = getprop("/orientation/pitch-deg");
            setprop("/autopilot/settings/target-pitch-deg",pitchdeg);

            modeh = "dg-heading-hold";
            headingdeg = getprop("/orientation/heading-magnetic-deg");
            setprop("/autopilot/settings/heading-bug-deg",headingdeg);
        }
        else {
            clutch = constant.FALSE;

            modev = "";
            modeh = "";
        }

        setprop("/autopilot/locks/altitude",modev);
        setprop("/autopilot/locks/heading",modeh);
        setprop("/controls/autoflight/autopilot[0]/engaged",clutch);
    }
}

# altitude hold
Autopilot.apaltitudeexport = func {
    modeh = getprop("/autopilot/locks/heading");

    # only if autopilot on
    if( modeh == "dg-heading-hold" or modeh == "true-heading-hold" ) {
        modev = getprop("/autopilot/locks/altitude");
        if( modev != "altitude-hold" ) {
            switch = constant.TRUE;

            modev = "altitude-hold";
            altitudeft = getprop("/instrumentation/altimeter/indicated-altitude-ft");
            setprop("/autopilot/settings/target-altitude-ft",altitudeft);
        }
        else {
            switch = constant.FALSE;

            modev = "pitch-hold";
            pitchdeg = getprop("/orientation/pitch-deg");
            setprop("/autopilot/settings/target-pitch-deg",pitchdeg);
        }

        setprop("/autopilot/locks/altitude",modev);
        setprop("/controls/autoflight/altitude-switch",switch);
    }
}

# pitch autopilot :
# - coefficient
Autopilot.pitchexport = func( coef ) {
    altitudemode = getprop("/autopilot/locks/altitude");
    if( altitudemode != nil and altitudemode != "" ) {
        pitchdeg = getprop("/autopilot/settings/target-pitch-deg");
        if( coef >= 0 ) {
            pitchdeg = pitchdeg + 0.15 * coef;
            if( pitchdeg > 12 ) {
                pitchdeg = 12;
            }
        }
        else {
            pitchdeg = pitchdeg + 0.15 * coef;
            if( pitchdeg < -12 ) {
                pitchdeg = -12;
            }
        }
        setprop("/autopilot/settings/target-pitch-deg",pitchdeg);

        result = constant.TRUE;
    }
    else {
        result = constant.FALSE;
    }

    return result;
}

Autopilot.real = func {
   mode = getprop("/autopilot/locks/altitude");
   if( mode != nil and mode != "" ) {
       headingdeg = getprop("/orientation/heading-magnetic-deg");
       setprop("/autopilot/settings/heading-bug-deg",headingdeg);
       mode = "dg-heading-hold";
   }
   else {
       mode = "";
   }
   setprop("/autopilot/locks/heading",mode);
}

# autopilot help testing during speed-up
Autopilot.schedule = func {
   # adding a waypoint swaps to true heading hold
   mode = getprop("/autopilot/locks/heading");
   if( mode == "true-heading-hold" ) {

       # keeps autopilot
       if( !getprop("/systems/crew/copilot/activ") ) { 
           me.real();
       }
   }
}
