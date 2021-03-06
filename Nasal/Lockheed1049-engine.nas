# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =======
# ENGINES
# =======

Engine = {};

Engine.new = func {
   var obj = { parents : [Engine,System],

               LOWBLOWER : 0,
               HIGHBLOWER : 1,

               LOWPSI : 20.0,

               LOWRPM : 1350.0,
               HIGHRPM : 2900.0
         };

   obj.init();

   return obj;
};

Engine.init = func {
   me.inherit_system("/systems/engines");
}

Engine.schedule = func {
   me.supercharger();
   me.red_oil();
   me.orange_pitch();
}

Engine.red_oil = func {
   var value = constant.FALSE;

   for( var i = 0; i < constantaero.NBENGINES; i = i+1 ) {
        if( me.itself["engine"][i].getChild("oil-pressure-psi").getValue() < me.LOWPSI ) {
            value = constant.TRUE;
        }
        else {
            value = constant.FALSE;
        }

        me.itself["engine-sys"][i].getChild("oil-low").setValue( value );
   }
}

Engine.orange_pitch = func {
   var value = constant.FALSE;
   var rpm = 0.0;

   for( var i = 0; i < constantaero.NBENGINES; i = i+1 ) {
        rpm = me.itself["engine"][i].getChild("rpm").getValue();

        if( rpm < me.LOWRPM or rpm >= me.HIGHRPM ) {
            value = constant.TRUE;
        }
        else {
            value = constant.FALSE;
        }

        me.itself["engine-sys"][i].getChild("propeller-low-high").setValue( value );
   }
}

Engine.supercharger = func {
   var value = 0;

   for( var i = 0; i < constantaero.NBENGINES; i = i+1 ) {
        if( me.itself["engine-ctrl"][i].getChild("blower-high").getValue() ) {
            value = me.HIGHBLOWER
        }
        else {
            value = me.LOWBLOWER
        }

        if( me.itself["engine-sys"][i].getChild("supercharger-gear").getValue() != value ) {
            me.itself["engine-sys"][i].getChild("supercharger-gear").setValue( value );
        }
   }
}
