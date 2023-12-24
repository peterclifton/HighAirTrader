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
    var result = "";
    var apts = findAirportsWithinRange(100);
    var size_ = size(apts);

    if(size_ > 1) {
        var selection = math.floor((rand() * (size_ - 1.01)) +1);
        result = apts[selection]
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


