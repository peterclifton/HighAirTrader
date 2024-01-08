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

var speed_up = func {
	if (getprop("/sim/highairtrader/configs/leaderboard")==1) {
        screen.log.write("Speed-up disabled at the moment.");
    } else {
        controls.speedup(1);
    }
}

var speed_down = func {
	if (getprop("/sim/highairtrader/configs/leaderboard")==1) {
        screen.log.write("Speed-down disabled at the moment.");
    } else {
        controls.speedup(-1);
    }
}