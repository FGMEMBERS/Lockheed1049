# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =========
# AUTOPILOT
# =========

Autopilot = {};

Autopilot.new = func {
   var obj = { parents : [Autopilot,System],

               AUTOPILOTSEC : 2.0
         };

   obj.init();

   return obj;
};

Autopilot.init = func {
   me.inherit_system("/systems/autopilot");

   # glows 35 to 45 times per minute
   aircraft.light.new(me.itself["root"].getChild("gyro-beacon").getPath(), [0.03, 1.30 + rand()*0.38]);
}

# autopilot hold
Autopilot.apexport = func {
    var modeh = "";
    var modev = me.itself["autopilot"].getChild("altitude").getValue();
    var clutch = constant.FALSE;

    # if not altitude on
    if( modev != "altitude-hold" ) {
        modeh = me.itself["autopilot"].getChild("heading").getValue();
        if( modev != "pitch-hold" or ( modeh != "dg-heading-hold" and modeh != "true-heading-hold" ) ) {
            clutch = constant.TRUE;

            modev = "pitch-hold";
            var pitchdeg = me.noinstrument["pitch"].getValue();
            me.itself["autopilot-set"].getChild("target-pitch-deg").setValue(pitchdeg);

            modeh = "dg-heading-hold";
            var headingdeg = me.noinstrument["heading"].getValue();
            me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);
        }
        else {
            modeh = "";
            modev = "";
        }

        me.itself["autopilot"].getChild("altitude").setValue(modev);
        me.itself["autopilot"].getChild("heading").setValue(modeh);
        me.itself["autopilot-ctrl"].getNode("autopilot").getChild("engaged").setValue(clutch);
    }
}

# altitude hold
Autopilot.apaltitudeexport = func {
    var modev = "";
    var modeh = me.itself["autopilot"].getChild("heading").getValue();
    var switch = constant.FALSE;

    # only if autopilot on
    if( modeh == "dg-heading-hold" or modeh == "true-heading-hold" ) {
        modev = me.itself["autopilot"].getChild("altitude").getValue();
        if( modev != "altitude-hold" ) {
            switch = constant.TRUE;

            modev = "altitude-hold";
            var altitudeft = me.dependency["altimeter"].getValue();
            me.itself["autopilot-set"].getChild("target-altitude-ft").setValue(altitudeft);
        }
        else {
            modev = "pitch-hold";
            var pitchdeg = me.noinstrument["pitch"].getValue();
            me.itself["autopilot-set"].getChild("target-pitch-deg").setValue(pitchdeg);
        }

        me.itself["autopilot"].getChild("altitude").setValue(modev);
        me.itself["autopilot-ctrl"].getChild("altitude-switch").setValue(switch);
    }
}

# manual setting of heading
Autopilot.headingexport = func( coef ) {
    var headingmode = me.itself["autopilot"].getChild("heading").getValue();
    var result = constant.FALSE;

    if( headingmode != nil and headingmode == "dg-heading-hold" ) {
        var headingdeg = me.itself["autopilot-set"].getChild("heading-bug-deg").getValue();

        headingdeg = headingdeg + 1.0 * coef;
        headingdeg = constant.truncatenorth(headingdeg);
        
        me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);

        result = constant.TRUE;
    }

    return result;
}

# manual setting of pitch
Autopilot.pitchexport = func( coef ) {
    var altitudemode = me.itself["autopilot"].getChild("altitude").getValue();
    var result = constant.FALSE;

    if( altitudemode != nil and altitudemode != "" ) {
        var pitchdeg = me.itself["autopilot-set"].getChild("target-pitch-deg").getValue();

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
        me.itself["autopilot-set"].getChild("target-pitch-deg").setValue(pitchdeg);

        result = constant.TRUE;
    }

    return result;
}

Autopilot.schedule = func {
   # TEMPORARY work around for heading modes PID :
   # heading modes banks into the direction, before engagement.
   if( me.itself["autopilot"].getChild("heading").getValue() != "dg-heading-hold" ) {
       # sets the value early.
       var headingdeg = me.noinstrument["heading"].getValue();
       me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);
   }
}

Autopilot.real = func {
   var mode = me.itself["autopilot"].getChild("altitude").getValue();

   if( mode != nil and mode != "" ) {
       var headingdeg = me.noinstrument["heading"].getValue();
       me.itself["autopilot-set"].getChild("heading-bug-deg").setValue(headingdeg);
       mode = "dg-heading-hold";
   }
   else {
       mode = "";
   }
   me.itself["autopilot"].getChild("heading").setValue(mode);
}
