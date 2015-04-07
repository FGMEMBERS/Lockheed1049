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

               rates : 0.0,

               HIGHBLOWERFT : 12500.0
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
   var pair = constant.FALSE;
   var target = constant.FALSE;

   if( me.noinstrument["altitude"].getValue() > me.HIGHBLOWERFT ) {
       target = constant.TRUE;
   }

   for( var i = 0; i < constantaero.NBENGINES; i = i+1 ) {
        if( me.dependency["engine"][i].getChild("blower-high").getValue() != target ) {
            if( me.can() ) {
                if( !pair ) {
                    var j = 0;

                    pair = constant.TRUE;

                    if( i == constantaero.ENGINE1 ) {
                        j = constantaero.ENGINE4;
                    }
                    else if( i == constantaero.ENGINE2 ) {
                        j = constantaero.ENGINE3;
                    }
                    else if( i == constantaero.ENGINE3 ) {
                        j = constantaero.ENGINE2;
                    }
                    else {
                        j = constantaero.ENGINE1;
                    }

                    me.dependency["engine"][i].getChild("blower-high").setValue( target );
                    me.dependency["engine"][j].getChild("blower-high").setValue( target );
                    me.done("blower-" ~ i);
                }
            }
        }
   }
}
