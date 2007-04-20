# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron



# =========
# CONSTANTS
# =========

Constant = {};

Constant.new = func {
   obj = { parents : [Constant],

           TRUE : 1.0,                             # no boolean
           FALSE : 0.0,

# time
           HOURTOSECOND : 3600.0,
           MINUTETOSECOND : 60.0,

# weight
           GALUSTOLB : 6.6,                        # 1 US gallon = 6.6 pound
           LBTOGALUS : 0.0
         };

   obj.init();

   return obj;
};

Constant.init = func {
   me.LBTOGALUS = 1 / me.GALUSTOLB;
}
