# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =======
# GENERIC
# =======

Generic = {};

Generic.new = func {
   var obj = { parents : [Generic],

           click : nil,

           generic : aircraft.light.new("/instrumentation/generic",[ 1.5,0.2 ])
         };

   obj.init();

   return obj;
};

Generic.init = func {
   me.click = props.globals.getNode("/instrumentation/generic/click");

   me.generic.toggle();
}

Generic.toggleclick = func {
   var sound = constant.TRUE;

   if( me.click.getValue() ) {
       sound = constant.FALSE;
   }

   me.click.setValue( sound );
}


# ===============
# TERRAIN WARNING
# ===============

TerrainWarning = {};

TerrainWarning.new = func {
   var obj = { parents : [TerrainWarning,System],

               TERRAINSEC : 1.0,

               AGLM : [ 0, 500, 1000, 2000 ]
         };

   obj.init();

   return obj;
}

TerrainWarning.init = func {
    me.inherit_system("/instrumentation/terrain-warning");
}

TerrainWarning.schedule = func {
    var light = constant.FALSE;
    var j = 0;

    var aglft = me.noinstrument["aglft"].getValue();
    var selector = me.itself["root"].getChild("selector").getValue();

    selector = selector + 1;

    for( var i = 0; i < constantaero.NBGEARS; i = i+1 ) {
         j = i + 1;

         if( aglft >= me.AGLM[i] and aglft <= me.AGLM[j] and me.AGLM[selector] >= me.AGLM[j] ) {
             light = constant.TRUE;
         }

         else {
             light = constant.FALSE;
         }

         me.itself["light"][i].setValue( light );
    }
}


# =============
# SPEED UP TIME
# =============

Daytime = {};

Daytime.new = func {
   var obj = { parents : [Daytime,System],

               SPEEDUPSEC : 1.0,

               CLIMBFTPMIN : 2500,                                           # max climb rate
               MAXSTEPFT : 0.0,                                              # altitude change for step

               lastft : 0.0
         };

   obj.init();

   return obj;
}

Daytime.init = func {
    me.inherit_system("/instrumentation/clock");

    var climbftpsec = me.CLIMBFTPMIN / constant.MINUTETOSECOND;

    me.MAXSTEPFT = climbftpsec * me.SPEEDUPSEC;
}

Daytime.schedule = func {
   var altitudeft = me.noinstrument["altitude"].getValue();
   var speedup = me.noinstrument["speed-up"].getValue();

   if( speedup > 1 ) {
       var multiplier = 0.0;
       var offsetsec = 0.0;
       var warp = 0.0;
       var stepft = 0.0;
       var maxft = 0.0;
       var minft = 0.0;

       # accelerate day time
       multiplier = speedup - 1;
       offsetsec = me.SPEEDUPSEC * multiplier;
       warp = me.noinstrument["warp"].getValue() + offsetsec; 
       me.noinstrument["warp"].setValue(warp);

       # safety
       stepft = me.MAXSTEPFT * speedup;
       maxft = me.lastft + stepft;
       minft = me.lastft - stepft;

       # too fast
       if( altitudeft > maxft or altitudeft < minft ) {
           me.noinstrument["speed-up"].setValue(1);
       }
   }

   me.lastft = altitudeft;
}
