# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =============
# SPEED UP TIME
# =============

DayTime = {};

DayTime.new = func {
   obj = { parents : [DayTime],

           altitudenode : nil,
           thesim : nil,
           warpnode : nil,

           SPEEDUPSEC : 1.0,

           CLIMBFTPMIN : 1200,                                       # average climb rate
           MAXSTEPFT : 0.0,                                          # altitude change for step

           lastft : 0.0
         };

   obj.init();

   return obj;
}

DayTime.init = func {
    climbftpsec = me.CLIMBFTPMIN / constant.MINUTETOSECOND;
    me.MAXSTEPFT = climbftpsec * me.SPEEDUPSEC;

    me.altitudenode = props.globals.getNode("/position/altitude-ft");
    me.thesim = props.globals.getNode("/sim");
    me.warpnode = props.globals.getNode("/sim/time/warp");
}

DayTime.schedule = func {
   altitudeft = me.altitudenode.getValue();

   speedup = me.thesim.getChild("speed-up").getValue();
   if( speedup > 1 ) {
       # accelerate day time
       multiplier = speedup - 1;
       offsetsec = me.SPEEDUPSEC * multiplier;
       warp = me.warpnode.getValue() + offsetsec; 
       me.warpnode.setValue(warp);

       # safety
       stepft = me.MAXSTEPFT * speedup;
       maxft = me.lastft + stepft;
       minft = me.lastft - stepft;

       # too fast
       if( altitudeft > maxft or altitudeft < minft ) {
           me.thesim.getChild("speed-up").setValue(1);
       }
   }

   me.lastft = altitudeft;
}
