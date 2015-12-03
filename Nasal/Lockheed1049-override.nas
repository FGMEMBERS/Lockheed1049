# ========================
# OVERRIDING NASAL GLOBALS
# ========================

# overrides keyboard for autopilot adjustment or floating view.

override_incElevator = controls.incElevator;

controls.incElevator = func {
    var sign = 1.0;
    
    if( arg[0] < 0.0 ) {
	sign = -1.0;
    }
    
    if( globals.Lockheed1049.seatsystem == nil ) {
        override_incElevator(arg[0], arg[1]);
    }
    elsif( !globals.Lockheed1049.seatsystem.movelengthexport(-0.01 * sign) ) {
        if( !globals.Lockheed1049.autopilotsystem.pitchexport(5.0 * sign) ) {
            # default
            override_incElevator(arg[0], arg[1]);
        }
    }
}

override_incAileron = controls.incAileron;

controls.incAileron = func {
    var sign = 1.0;
    
    if( arg[0] < 0.0 ) {
	sign = -1.0;
    }
    
    if( globals.Lockheed1049.seatsystem == nil ) {
        override_incAileron(arg[0], arg[1]);
    }
    elsif( !globals.Lockheed1049.seatsystem.movewidthexport(0.01 * sign) ) {
        if( !globals.Lockheed1049.autopilotsystem.headingexport(1.0 * sign) ) {
            # default
            override_incAileron(arg[0], arg[1]);
        }
    }
}

override_incThrottle = controls.incThrottle;

controls.incThrottle = func {
    var sign = 1.0;
    
    if( arg[0] < 0.0 ) {
	sign = -1.0;
    }
    
    if( globals.Lockheed1049.seatsystem == nil ) {
        override_incThrottle(arg[0], arg[1]);
    }
    elsif( !globals.Lockheed1049.seatsystem.moveheightexport(0.01 * sign) ) {
        # default
        override_incThrottle(arg[0], arg[1]);
    }
}
