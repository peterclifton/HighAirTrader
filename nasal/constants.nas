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
# This file contains 'addon level' constants. Most are scalars or vectors but
# some are functions which map from some (usually scalar) input to a scalar 
# output in a 1 to 1 deterministic fashion.

# job pay baserate
var basePayPerNm = 2.0; #i.e. pounds per nm


# Filepaths related to game data storage
var chronoLog_file_name = 'chronoLog.txt';  
var pendingoffer_file_name = 'pendingoffer.txt';
var storagedirpath = getprop("/sim/fg-home") ~ "/Export/Addons/org.flightgear.addons.HighAirTrader/";


# List of the different goods that the game asks to be transported 
var goodslist = [
    "parcels",
    "documents",
    "electronic goods",
    "a passenger",
    "bags of rice",
    "cash",
    "gold",
    "silver",
    "computer games",
    "a VIP",
    "the Tiapan",
    "an official",
    "special gadgets",
    "medical supplies",
    "blood supplies",
    "food supplies",
    "whisky",
    "vodka",
    "soft drinks",
    "tea leaves",
    "coffee beans",
    "mail bags",
    "a high tech device"
    ];


# A list of hours of the day, office hours are more common so if randomly 
# selecting and element from this they are more likely to be chosen
var hourPdf = [0,
               1,
               2,
               3,
               4,
               5,5,
               6,6,
               7,7,7,7,7,7,7,7,7,7,
               8,8,8,8,8,8,8,8,8,8,
               9,9,9,9,9,9,9,9,9,9,
               10,10,10,10,10,10,10,10,10,10,
               11,11,11,11,11,11,11,11,11,11,
               12,12,12,12,12,12,12,12,12,12,
               13,13,13,13,13,13,13,13,13,13,
               14,14,14,14,14,14,14,14,14,14,
               15,15,15,15,
               16,16,
               17,
               18,
               19,
               20,
               21,
               22,
               23
               ];


var getWindMulti = func(ws) {
    # Get a job difficulty multiplier for a given windspeed
    # :params ws: (double): windspeed in kts
    # :returns double
    ws3f = ws;
    if(ws < 3) {
        ws3f = 3;
    }
    return 1.0 + (0.05 * (math.pow((ws3f-3),2)));
};


var getRainMulti = func(rain) {
    # Get a job difficulty multiplier for a given rain level
    # :params rain: (double): rain value
    # :returns double
    var rm = 1;
    if(rain>0) {
        rm = 2;
    }
    return rm;
};


var getTimeMulti = func(min_start_hour) {
    # Get a job difficulty multiplier for a given hour of day
    # :params min_start_hour: (int) 
    # :returns double
    var hourMultiDict = {0: 3.5,
                     1: 3.6,
                     2: 3.6,
                     3: 3.6,
                     4: 3.3,
                     5: 2.9,
                     6: 2.3,
                     7: 1.5,
                     8: 1.1,
                     9: 1.0,
                    10: 1.0,
                    11: 1.0,
                    12: 1.0,
                    13: 1.0,
                    14: 1.1,
                    15: 1.5,
                    16: 1.7,
                    17: 2.0,
                    18: 3.0,
                    19: 2.6,
                    20: 2.9,
                    21: 3.2,
                    22: 3.4,
                    23: 3.6 };

        return hourMultiDict[min_start_hour]; 
};

# A list of airports to be used for long-haul freight destinations
# at the moment this list is hard coded which is not ideal (as introduces
# a fragility and technical debt) but will do
# until this hard coded approach can be replaced by a game data driven
# logic that is not expensive at runtime.
# note this list is mainly a subset of the airports listed at:
# https://wiki.flightgear.org/List_of_developed_airports
var long_haul_airports_ICAO_list = ['CYGK',
                                      'EDDC',
                                      'EDDF',
                                      'EDDB',
                                      'EDDH',
                                      'EDDL',
                                      'EDDM',
                                      'EDDP',
                                      'EDDS',
                                      'EDDW',
                                      'EDAZ',
                                      'EDXW',
                                      'EDHL',
                                      'EDKB',
                                      'EFHK',
                                      'EGFF',
                                      'EGGP',
                                      'EGKK',
                                      'EGLL',
                                      'EGPH',
                                      'EHAM',
                                      'EIDW',
                                      'ENAL',
                                      'ESGP',
                                      'KATL',
                                      'KAKR',
                                      'KBOS',
                                      'KBWI',
                                      'KCVG',
                                      'KDCA',
                                      'KDEN',
                                      'KDTW',
                                      'KIND',
                                      'KJFK',
                                      'KLAX',
                                      'KOAK',
                                      'KORD',
                                      'KOSH',
                                      'KSEA',
                                      'KSFO',
                                      'KSLC',
                                      'LDSP',
                                      'LEBB',
                                      'LEMD',
                                      'LFPG',
                                      'LFRB',
                                      'LIME',
                                      'LKPR',
                                      'LOWI',
                                      'LROP',
                                      'LSGG',
                                      'RJTT',
                                      'RJCC',
                                      'ROAH',
                                      'RKSI',
                                      'RPLL',
                                      'SAEZ',
                                      'SVMI',
                                      'TDPD',
                                      'TFFF',
                                      'SBCT',
                                      'SBGR',
                                      'SKRG',
                                      'VIDP',
                                      'VQPR',
                                      'VHHH',
                                      'CYYT'];
