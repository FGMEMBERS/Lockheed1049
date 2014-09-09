# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =====
# DOORS
# =====

Doors = {};

Doors.new = func {
   var obj = { parents : [Doors,System],

               seat : SeatRail.new(),

               crew : nil,
               flightstation : nil,
               passenger : nil
         };

   obj.init();

   return obj;
};

Doors.init = func {
   me.inherit_system( "/systems/doors" );

   me.crew = aircraft.door.new(me.itself["root-ctrl"].getNode("crew").getPath(), 10.0);
   me.flightstation = aircraft.door.new(me.itself["root-ctrl"].getNode("flight-station").getPath(), 7.0);
   me.passenger = aircraft.door.new(me.itself["root-ctrl"].getNode("passenger").getPath(), 10.0);

   # user customization
   if( me.itself["root-ctrl"].getNode("flight-station").getChild("opened").getValue() ) {
       me.flightstation.toggle();
   }
}

Doors.crewexport = func {
   me.crew.toggle();
}

Doors.flightstationexport = func {
   var state = constant.TRUE;

   me.flightstation.toggle();

   if( me.itself["root-ctrl"].getNode("flight-station").getChild("opened").getValue() ) {
       state = constant.FALSE;
   }

   me.itself["root-ctrl"].getNode("flight-station").getChild("opened").setValue(state);
}

Doors.passengerexport = func {
   me.passenger.toggle();
}

Doors.seatexport = func( seat ) {
   me.seat.toggle( seat );
}

Doors.schedule = func {
   var warning = constant.FALSE;

   if( me.itself["root-ctrl"].getNode("passenger").getChild("position-norm").getValue() > 0.0 ) {
       warning = constant.TRUE;
   }

   # warning light
   me.itself["root"].getChild("passenger").setValue(warning);
}


# ===========
# GEAR SYSTEM
# ===========

Gear = {};

Gear.new = func {
   var obj = { parents : [Gear,System],

               FLIGHTSEC : 2.0,

               GEARDOWN : 1.0,
               GEARUP : 0.0,

               STEERINGKT : 40
         };

   obj.init();

   return obj;
};

Gear.init = func {
   me.inherit_system( "/systems/gear" );

   aircraft.steering.init(me.itself["root-ctrl"].getChild("brake-steering").getPath());
}

Gear.steeringexport = func {
   var result = 0.0;

   # taxi with steering wheel, rudder pedal at takeoff
   if( me.noinstrument["airspeed"].getValue() < me.STEERINGKT ) {

       # except forced by menu
       if( !me.dependency["steering"].getChild("pedal").getValue() ) {
           result = 1.0;
       }
   }

   me.dependency["steering"].getChild("wheel").setValue(result);
}

Gear.schedule = func {
   me.steeringexport();
   me.indicator();
}

Gear.indicator = func {
   var pos = 0.0;
   var safe = constant.TRUE;
   var unsafe = constant.FALSE;

   for( var i = 0; i < constantaero.NBGEARS; i = i+1 ) {
        pos = me.itself["gear"][i].getChild("position-norm").getValue();
        if( pos == me.GEARDOWN ) {
            safe = constant.TRUE;
        }
        else {
            if( pos != me.GEARUP ) {
                unsafe = constant.TRUE;
            }

            safe = constant.FALSE;
        }

        me.itself["gear-sys"][i].getChild("safe").setValue( safe );
   }

   me.itself["root"].getChild("unsafe").setValue( unsafe );
}
