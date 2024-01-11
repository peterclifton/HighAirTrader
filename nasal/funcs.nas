# HighAirTrader - Add-on for FlightGear
# Copyright (C) 2023 Peter Clifton
# Written and developed by Peter Clifton and Thomas Clifton

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# SUMMARY----------------------------------------------------------------------
# This file contains functions that may be called when needed from any other
# file in this add-on. Generally speaking each function here should do one and
# only one thing, and not have state changing side effects


# --------------------- Flightgear world related functions --------------------

var getHourPartOfDaySecs = func(daysecs) {
    # returns hrs: int
    var hrs = math.floor((daysecs/(60*60)));
    return hrs;
}

var getMinsPartOfDaySecs = func(daysecs) {
    # returns mins: int
    var mins = math.floor( ((math.fmod(daysecs, 60*60))/60)); 
    return mins;
}

var getClosestAirportId = func() {
    # :returns result: a string indicating the airport ICAO Id
    var ap = props.globals.getNode("/sim/airport/closest-airport-id").getValue();
    return ap;
}

var getClosestAirport = func() {
    # Returns the closes airport
    # :returns result: an airport object
    var r = findAirportsByICAO(getClosestAirportId());
    return r[0];
}

var getSecondClosestAirportId = func() {
    # :returns result: a string indicating the airport ICAO Id
    var result = "";
    var apts = findAirportsWithinRange(100);
    if(size(apts) > 1) {
        result = apts[1].id
    }
    return result;
}

var getRandNearAirportId = func() {
    # Returns a random airport within 100nm
    # :returns result: a string indicating the airport ICAO Id
    var result = "";
    var apts = findAirportsWithinRange(100);
    var size_ = size(apts);

    if(size_ > 1) {
        var selection = math.floor((rand() * (size_ - 1.01)) +1);
        result = apts[selection].id
    }
    return result;
}

var getRandNearAirport = func() {
    # Selects and returns a random airport within 100nm
    # :returns result: an airport object
    var result = ""; # would probably be better for this to be nil rather than the empty string?
    var apts = findAirportsWithinRange(100);
    var size_ = size(apts);

    if(size_ > 1) {
        var selection = math.floor((rand() * (size_ - 1.01)) +1);
        result = apts[selection]
    }
    return result;
}

var getLongHaulDestiAirport = func() {
    # Selects and returns an airport to serve as the destination for a
    # long haul freight flight
    # :returns result: an airport object
    #var result = airportinfo('EGLL'); # dummy function at moment - just returns London Heathrow
    var closest_airport_id = getClosestAirportId();
    var ap_candidate_list = sublist(constants.long_haul_airports_ICAO_list, closest_airport_id);
    var chosen_ap_id = getRandElementOfVector(ap_candidate_list);

    # findAirportsByICAO returns a vector with matching airports
    # as we are searching by full ICAO we expect that it will be a vector
    # of size 1 (in any case we will take the 1st element so would not matter
    # to us if it was bigger). However if he ICAO we passed it did not match
    # any airports in FlightGear it will return an empty vector
    # just in case this should happen for some reason (e.g. say because of an erroneous
    # value in constants.long_haul_airports_ICAO_list) we deal with this below
    # by checking the size of the returned vector and if it is size 0
    # we just return EGLL airport (Heathrow) as a fallback.
    var result = nil;
    var vector_with_matching_airport = findAirportsByICAO(chosen_ap_id);
    if (size(vector_with_matching_airport) > 0) {
        result = vector_with_matching_airport[0];
    }
    else {
        result = findAirportsByICAO('EGLL')[0];
    }
    return result;
}

var getLocalTime = func() {
    # Gets the local time in seconds
    # Returns a dictionary with localTimeSecs being the total seconds
    # hrs being the 0-23 hour part of current time
    # mins being the 0-59 min part of current time
    # :returns result: hash
    
    # divide by 60*60 to get in hours:
    var lds = props.globals.getNode("/sim/time/local-day-seconds").getValue(); 
    var hrs  = math.floor((lds/(60*60))); #get hour part of local time
    var mins = math.floor( ((math.fmod(lds, 60*60))/60)); # get min part

    var result = { 'localTimeSecs': lds,
                   'hrs':hrs,
                   'mins':mins
                 };

    return result;
}


var getCurrency = func() {
    # Gets the currency
    # :returns result: string
    var currency = "";
    if(getprop("/sim/highairtrader/configs/currency") == "Dollars") {
            currency ="$";
    }
    else if (getprop("/sim/highairtrader/configs/currency") == "Pounds") {
        currency ="£";        
    }
    else if(getprop("/sim/highairtrader/configs/currency") == "Euros") {
        currency ="€";
    }
    else {
        currency = "$";
    }
    return currency;
}


var getFreightMarket = func() {
    # Gets the Freight-market (i.e. Short-haul, Long-haul)
    # :returns result: string
    var haul = "";
    if(getprop("/sim/highairtrader/configs/freight-market") == "Short-haul") {
            haul = "short-haul";
    }
    else if (getprop("/sim/highairtrader/configs/freight-market") == "Long-haul") {
        haul = "long-haul";        
    }
    # Future feature:
    #else if(getprop("/sim/highairtrader/configs/freight-market") == "Long-haul") {
    #    currency ="long-haul";
    #}
    else {
        haul = "short-haul";
    }
    return haul;
}

var getTotalFuelLbs = func() {
    # Get current total-fuel-lbs
    # :returns fuelLbs: double

    # divide by 60*60 to get in hours:
    var fuelLbs = props.globals.getNode("/consumables/fuel/total-fuel-lbs").getValue(); 
    return fuelLbs;
}

var negligibleGroundSpeed = func() {
    # Checks to see if the current ground speed is negligible or not
    # if groundspeed-kt is under 1 will return 1 else 0
    # :returns result: bool

    var groundspeedkt = props.globals.getNode("/velocities/groundspeed-kt").getValue();
    if (groundspeedkt < 1.0) {
        result = 1;
    }
    else {
        result = 0;
    }
    return result;
}

var brokenGearDetected = func() {
    # Attempts to detect if any of the landing gears are broken
    # Returns 1 if detects any broken gears, 0 otherwise
    # :returns broken_gear_detected: bool
    #
    # Notes: using the property tree to check for broken landing gear is
    # dependent on how the aircraft presents itself in the property tree.
    # Some aircraft will not have any such property for us to check etc.
    #
    # In the basic case of the C172p FG default aircraft using the JBSim
    # FDM we could do something like:
    # data = props.globals.getNode("/fdm/jsbsim/gear").getChildren("unit")
    # then foreach item in data check if a child property exists called 'broken'
    # (e.g. item.getChild("broken") != nil) and then inspect the value of that 
    # property (i.e.: 1 => gear is broken, 0 => not broken)
    #
    # However not all aircraft use the JBSim FDM and even those that do
    # might not have the /fdm/jsbsiim/gear properties.
    #
    # Given this, the approach / structure of this function is as follows:
    # 1) Set a flag to 0 
    # 2) Carry out a series of tests which will trip the flag to 1 if any
    #    return a positive result
    #
    # All of the test functions called from this function must be such that they
    # will return 1 if they detect broken gear, else 0 (including in the cases 
    # where the properties that the test seeks to inspect do not exist etc)
    #
    # At the moment only one test has been added to this function but more could 
    # be so long as they conform to the above approach.

    
    # Set our flag to 0. If any of the checks return a positive the flag will
    # be set to 1 and this function will return 1
    var broken_gear_detected = 0;

    # Check 1: checking /fdm/jsbsim/gear properties
    # note if /fdm/jsbim/gear is not present then jsbsim_gear_broken() will 
    # just return 0
    if(jsbsim_gear_broken()){
        broken_gear_detected = 1;
    }
    # more tests can be added below if desired...
    
    # After all the tests have run, return our result:
    return broken_gear_detected;
}

var jsbsim_gear_broken = func() {
    # Attempts to detect if any of the landing gears are broken
    # using the /fdm/jsbsim/gear properties
    # Returns 1 if detects any broken gears, 0 if the properties indicate that
    # the gear is not broken or if those properties do not exist
    # :returns broken_gear_detected: bool

    var broken_gear_detected = 0;

    jsbsimGearInfo = props.globals.getNode("/fdm/jsbsim/gear"); 
    # if /fdm/jsbsim/gear does not exist jsbsimGearInfo will be nil, in which
    # case jsbsimGearInfo.getChildren("whatever") would throw an error
    # so we check before leaping with:
    if(jsbsimGearInfo != nil) {
        gdata = jsbsimGearInfo.getChildren("unit");
        # note if there are no "unit" children, gdata will be an empty list
        # which will be handled fine by the below foreach loop which will just
        # do nothing i.e. our flag will remain at 0
        foreach(item; gdata) {
            broken_status = item.getChild("broken");
            if (broken_status != nil) {
                if (broken_status.getValue() == 1) {
                    broken_gear_detected = 1;
                }
            }
        }
    }
    return broken_gear_detected;
}

# --------------------- Generic Functions -------------------------------------

var getRandElementOfVector = func(myvec) {
    #expects a non zero size vector!
    # :params myvec: a non-zero size vector
    # :returns a random element of said vector
    var i = math.floor(rand() * (size(myvec) - 0.01));
    return myvec[i];
}

var sublist = func(myvec, elem_to_exclude) {
    # expects a vector and a scalar, will return a new vector which is like the
    # original one but excluding any elements which equal the elem_to_exclude
    # if an empty vector is passed to it will return an empty vector
    # :params myvec: a vector
    # :params elem_to_exclude:
    # :returns result: a vector excluding any element which equals elem_to_exclude
    var result = [];
    foreach (element; myvec) {
        if (element != elem_to_exclude) {
            append(result, element);
        }
    }
    return result;
}

var check_leaderboard = func {
    print("asdfs");
    if (getprop("/sim/highairtrader/configs/leaderboard")==1) {
        setprop("/sim/highairtrader/lewf/enabled", 1);
    } else {
        setprop("/sim/highairtrader/lewf/enabled", 0);
    }
}

var speed_up = func {
    if (getprop("/sim/highairtrader/configs/mission")==1) {
        screen.log.write("Speed-up disabled at the moment.");
    } else {
        controls.speedup(1);
    }
}

var speed_down = func {
    if (getprop("/sim/highairtrader/configs/mission")==1) {
        screen.log.write("Speed-down disabled at the moment.");
    } else {
        controls.speedup(-1);
    }
}
