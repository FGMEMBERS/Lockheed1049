# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# ================
# VIRTUAL ENGINEER
# ================

VirtualEngineer = {};

VirtualEngineer.new = func {
   var obj = { parents : [VirtualEngineer,VirtualCrew,System],

               nightlighting : Nightlighting.new(),
               nightlighting2 : Nightlighting.new(),

               ENGINEERSEC : 15.0,
               BLOWERSEC : 4.0,

               rates : 0.0,

               HIGHFT : 11000.0,

               BLOWERHIGH : 1.0,
               BLOWERLOW : 0.0
         };

   obj.init();

   return obj;
};

VirtualEngineer.init = func {
   var path = "/systems/engineer";

   me.inherit_system(path);
   me.inherit_virtualcrew(path);

   me.rates = me.ENGINEERSEC;
   me.run();
}

VirtualEngineer.toggleexport = func {
   var launch = constant.FALSE;

   if( !me.itself["root-ctrl"].getChild("activ").getValue() ) {
       launch = constant.TRUE;
   }

   me.itself["root-ctrl"].getChild("activ").setValue(launch);
       
   if( launch and !me.is_running() ) {
       # must switch lights again
       me.nightlighting.set_task();
       me.nightlighting2.set_task();

       me.schedule();
   }
}

VirtualEngineer.lightingexport = func {
   me.nightlighting.engineerexport();
}

VirtualEngineer.pilotlightingexport = func {
   me.nightlighting2.pilotexport();
}

VirtualEngineer.schedule = func {
   me.reset();

   if( me.dependency["crew"].getChild("serviceable").getValue() ) {
       me.supervisor();
   }

   me.run();
}

VirtualEngineer.run = func {
   me.state = "";

   if( me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.set_running();

       me.rates = me.speed_ratesec( me.rates );
       settimer( func { me.schedule(); }, me.rates );
   }
}

VirtualEngineer.supervisor = func {
   me.rates = me.ENGINEERSEC;

   if( me.itself["root-ctrl"].getChild("activ").getValue() ) {
       me.set_activ();

       me.blower();

       me.nightlighting.engineer( me );

       if( me.dependency["crew-ctrl"].getChild("captain-busy").getValue() ) {
           me.nightlighting2.pilot( me );
       }

       me.rates = me.randoms( me.rates );
       me.timestamp();
   }

   me.itself["root"].getChild("activ").setValue(me.is_activ());
}

VirtualEngineer.blower = func {
   var times = me.BLOWERSEC;
   var target = me.BLOWERLOW;

   # in fact, done automatically by FDM
   if( me.noinstrument["altitude"].getValue() > me.HIGHFT ) {
       target = me.BLOWERHIGH;
   }

   for( var i = 0; i < 4; i = i+1 ) {
        if( me.dependency["engine"][i].getChild("blower").getValue() != target ) {
            times = me.speed_ratesec( me.BLOWERSEC );
            interpolate( me.dependency["engine"][i].getChild("blower").getPath(), target, times );
        }
   }
}
