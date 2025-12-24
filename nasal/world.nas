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
# This file contains classes that can be thought of as being analogous to 
# things that exist in the game world


# MODULE LEVEL VARIABLES-------------------------------------------------------

var verbose4debuging = 0; # Set to 1 for verbose output to console for debugging


# CLASSES----------------------------------------------------------------------


var Pilot = {
    # A class that provides information as if it were from the pilots point of
    # view, such as current local times, nearest airport, weather at the
    # location etc. Has functions that take a jobsheet and put info onto
    # the jobsheet before returning it.
    new: func() {
        var m = { parents: [Pilot] };
        m.info = me.getPilotInfo();
        m.weather = me.getWeather();
        return m;
    },
    getPilotInfo: func() {
        # :returns info: a hash with various infomation about the pilots 
        # current situation
        var info    = {};
        var loctime = funcs.getLocalTime();
        info.localTimeSecs  = loctime.localTimeSecs;
        info.hrs            = loctime.hrs;
        info.mins           = loctime.mins;
        info.totalFuelLbs   = funcs.getTotalFuelLbs();
        info.atAirportId    = funcs.getClosestAirportId();
        info.freight_market = funcs.getFreightMarket();
        return info;
    },
    update: func() {
        # Updates the info and weather attributes of the pilot object
        me.info    = me.getPilotInfo();
        me.weather = me.getWeather();
    },
    getWeather: func() {
        # :returns weather: a hash with various information about the 
        # weather at the current location
        var weather = {};
        var windSpeed       = props.globals.getNode("/environment/wind-speed-kt").getValue(); #double
        var rainNorm        = props.globals.getNode("/environment/rain-norm").getValue(); #double
        var visibilityM     = props.globals.getNode("/environment/visibility-m").getValue();
        # re sun-angle-rad: 0 is noon pie/2 is sunset/rise pie. no sun hours between pie/2 and pie
        var sunAngleRad     = props.globals.getNode("/sim/time/sun-angle-rad").getValue();

        weather.windSpeed       = windSpeed;
        weather.rainNorm        = rainNorm;
        weather.visibilityM     = visibilityM;
        weather.sunAngleRad     = sunAngleRad;
        return weather;
    },
    enter_accept_pending_offer_details: func(jobsheet) {
        # 'the pilot' enters the required info onto the jobsheet upon 
        # a pending offer being accepted
        # :params jobsheet
        # :returns jobsheet: i.e. same as the jobsheet that was passed
        #                    to the function but with the extra added details
        jobsheet.status              = 'ACCEPTED';
        jobsheet.startfuel_level_lbs = me.info.totalFuelLbs;
        jobsheet.actualstarttime     = me.info.localTimeSecs;
        return jobsheet;
    },
    enter_outcome_details_jobcomplete: func(jobsheet) {
        # 'the pilot' enters the required info onto the jobsheet upon 
        # completing a job.
        # :params jobsheet
        # :returns jobsheet: i.e. same as the jobsheet that was passed
        #                    to the function but with the extra added details
        jobsheet = me._enter_outcome_details(jobsheet,'COMPLETED');
        
        # findAirportsByICAO Returns a vector containing airport ghost objects 
        # which are (by default) airports whose ICAO code matches the search
        # string. Results are sorted by range from closest
        var destiAirport = findAirportsByICAO(jobsheet.toId)[0];

        # Work out distance to destination
        var heading_and_dist = courseAndDistance(destiAirport);
        var distance_to_desti = heading_and_dist[1];
        jobsheet.outcome_dist_todest = distance_to_desti;

        return jobsheet;
    },
    enter_outcome_details_aborted_other: func(jobsheet) {
        # 'the pilot' enters the required info onto the jobsheet upon 
        # aborting the job for a reason other than a crash 
        # :params jobsheet
        # :returns jobsheet
        jobsheet = me._enter_outcome_details(jobsheet,'ABORTED_OTHER');
        return jobsheet;
    },
    enter_outcome_details_aborted_crash: func(jobsheet) {
        # 'the pilot' enters the required info onto the jobsheet upon 
        # aborting the job due to a crash
        # :params jobsheet
        # :returns jobsheet
        jobsheet = me._enter_outcome_details(jobsheet,'ABORTED_CRASH');
        return jobsheet;
    },
    _enter_outcome_details: func(jobsheet, outcometype) {
        # Populate jobsheet with outcometime, outcomefuel_level_lbs, outcomeloc
        # :params: a jobsheet object, and a string to indicate the outcome type
        #          the string should be only one of the following: 'COMPLETED',
        #          'ABORTED_OTHER', 'ABORTED_CRASH'
        # :returns: a jobsheet object
        jobsheet.status      = 'RESOLVED';
        jobsheet.outcometype = outcometype;
        jobsheet = me._enter_outcome_time_loc_fuel(jobsheet);
        return jobsheet;
    },
    _enter_outcome_time_loc_fuel: func(jobsheet) {
        # Populate jobsheet with outcometime, outcomefuel_level_lbs, outcomeloc
        # :params: a jobsheet object
        # :returns: a jobsheet object
        jobsheet.outcometime           = me.info.localTimeSecs; 
        jobsheet.outcomefuel_level_lbs = me.info.totalFuelLbs; 
        jobsheet.outcomeloc            = me.info.atAirportId; 
        return jobsheet;
    },
};

var MaintenanceManager = {
    # A class for populating the 'maintenance' section of the jobsheet when
    # the job has been outcomed. Has functions that enter fuelusage, fuelcosts 
    # and any repair costs into the jobsheet before returning it
    new: func() {
        var m = { parents: [MaintenanceManager] };
        m.repairgroundcrew = RepairGroundCrew.new();
        m.pump = FuelPump.new();
        return m;
    },
    populate_maintenance_section: func(jobsheet) {
        # Populate jobsheet with fuelusage, fuelcosts, repair costs
        # :params: a jobsheet object
        # :returns: the jobsheet object with the added details
        jobsheet.fuelusage   = jobsheet.startfuel_level_lbs - jobsheet.outcomefuel_level_lbs;
        jobsheet.fuelcosts   = me.pump.getcost(jobsheet.fuelusage);

        if(jobsheet.outcometype == 'COMPLETED') {
            jobsheet.repaircosts = 0.0;
        }
        else if(jobsheet.outcometype == 'ABORTED_CRASH') {
            jobsheet.repaircosts = me.repairgroundcrew.getrepairbill();

        }
        else { # the only other option is 'ABORTED_OTHER'
            jobsheet.repaircosts = 0.0;
        }
        return jobsheet;
    },
};

var FuelPump = {
    # A class that provides a function mapping fuel use to cost
    new: func() {
        var m = { parents: [FuelPump] };
        m.gbp_cost_per_lb_of_fuel = 0.98;
        return m;
    },
    getcost: func(lbs) {
        # return cost in GBP of ammount of fuel as given by lbs
        return lbs * 0.98;
    },
};

var RepairGroundCrew = {
    # A class that provides a function to indicate the amount of repair costs incurred
    new: func() {
        var m = { parents: [RepairGroundCrew] };
        m.standard_repair_cost = 20000.00; # in GBP
        return m;
    },
    getrepairbill: func() {
        # When called returns cost to carry out repairs
        # Current version will just always return 20000,00 whenever called
        # As gets refined an check state of aircraft for damage etc check 
        # sim/crashed check fmd/ etc, see lobbook CrashDetector.nas for ideas!
        return me.standard_repair_cost;
    },
};

var Market = {
    # A class to facilitate the calculation of the value of a job based on 
    # certain variables e.g. such as distance, weather conditions etc
    new: func() {
        var m = { parents: [Market] };
        return m;
    },
    calcPayRate: func(baserate, distance, windspeed, rain, min_start_hour) {
        # Calculates the value of a job based on # certain variables e.g. 
        # such as distance, weather conditions etc
        # :params baserate: basic rate of pay per nm of distance
        # :params distance: distance in nm between to and from airports
        # :params windspeed: wind speed in knots, 
        #   i.e. as at: props.globals.getNode("/environment/wind-speed-kt").getValue()
        # :params rain: rain-norm value 
        #   i.e as at: props.globals.getNode("/environment/rain-norm").getValue() 
        # :params min_start_hour: an int between 0 to 23 (inclusive)
        # :returns pr: the job value in GBP 

        var windMulti = constants.getWindMulti(windspeed);
        var rainMulti = constants.getRainMulti(rain);
        var timeMulti = constants.getTimeMulti(min_start_hour);
        
        # the pay amount, pr, is then a function of these:
        var pr = (baserate * distance * windMulti * rainMulti * timeMulti) ; 

        if(verbose4debuging) { # If debuging is on then send some verbose output to the consle
             var debug1 = sprintf("pr[%s] = baserate[%.2f] * distance[%.2f] * wimdMulti[%.2f] * rainMulti[%.2f] * timeMulti[%.2f]<--min_start_hour[%.2f]",
                                   pr,      baserate,        distance,        windMulti,        rainMulti,        timeMulti,        min_start_hour);
         debug.dump(debug1);
        }
        return pr; 
    },
};

var Office = {
    # A class that provides functionality analogous to what an office might 
    # provider e.g. giving jobs to the pilot, signing off job sheets etc
    new: func() {
        var m = { parents: [Office] };
        return m;
    },
    signoff_jobsheet: func(jobsheet) {
        # Receives a job sheet which is ready to be signed off i.e. the 
        # jobsheet status should be 'RESOLVED' and then works out
        # the payment amount, enters that into the jobsheet and 
        # returns it. Should only call this sending it a jobsheet with all the 
        # required details to calculate the payment. i.e. this should be the 
        # last step of amending the jobsheet
        # :params jobsheet: a jobsheet object
        # :returns jobsheet: the jobsheet object (now with additional info added)
        if((jobsheet.status == "RESOLVED") and (jobsheet.outcometype != nil)) {
            var payment = 0.0;
                if(jobsheet.outcometype == "COMPLETED") {
                    # TODO: put in so checks if the depature time is in the right bounds 
                    if(jobsheet.toId == jobsheet.outcomeloc) {
                        payment = jobsheet.jobvalue;
                    }
                    else {
                        var d0 = jobsheet.distance; # distance to dest at start
                        var d1 = jobsheet.outcome_dist_todest; # distance to dest at outcome
                        # re dt: distance progressed towards destination (will 
                        # be negative if we have got further away)
                        var dt = d0 - d1;
                        # re w: distanced progressed as proportion of 
                        # originaldistance (will be negative if we have got further away)
                        var w  = (1.0*dt) / d0 ; 
                        payment = (w >= 0)? (jobsheet.jobvalue * ((1.5*w) - 1)) : (-1.0 * jobsheet.jobvalue) ;
                    }
                }
                else if(jobsheet.outcometype == "ABORTED_CRASH") {
                    payment = (-1.0 * jobsheet.jobvalue);
                }
                else if(jobsheet.outcometype == "ABORTED_OTHER") {
                    payment = (-1.0 * jobsheet.jobvalue);
                }
                else { # should not really be getting here
                    payment = (-1.0 * jobsheet.jobvalue);
                }
            jobsheet.paymentrecieved = payment;
        }
        return jobsheet;
    },
    get_peformance_summary: func() {
        # Returns a string summarising performance to date based on the existing
        # resolved jobsheets
        # :returns result: string
        var jsc = storage.JobSheetCabinet.new();
        var jsbook = paperwork.JobSheetBook.new(jsc.view_jobsheet_book());
        var result = jsbook.describe();
        # Get the pilot's current reputation level and append it to the summary string:
        var reputation_level = me.judge_reputation_level(jsbook);
        var rep_level_str = sprintf("(reputation level: %s )", reputation_level);
        result = result ~ " " ~ rep_level_str;
        return result;
    },
     judge_reputation_level: func(jobsheetbook) {
        # Maps the current running balance to a reputation category 
        # :params: a jobsheetbook object
        # :returns: rep_level: string
        # todo: consider moving this mapping constants.nas
        var balance = jobsheetbook.running_balance();
        var rep_level = "";
        if(balance < 5000.0) {
            rep_level = "obscure (Solo Operator)";
        }
        elsif(balance >= 5000.0 and balance < 20000.0) {
            rep_level = "local (Local Air Courier)";
        }
        elsif(balance >= 20000.0 and balance < 100000.0) {
            rep_level = "regional (Regional Air Courier)";
        }
        elsif(balance >= 100000.0 and balance < 1000000.0) {
            rep_level = "national (Domestic Air Logistics Company)";
        }
        elsif(balance >= 1000000.0 and balance < 2000000.0) {
            rep_level = "International (International Air Carrier)";
        }
        else { # i.e. balance is greater than or equal to 2M
            rep_level = "global (Multinational Air Logistics Group)";
        }
        return rep_level;
    },
    shred_all_paperwork: func() {
        # Caution: calling this will reset all game records
        # :returns void
        var a = storage.PendingOfferDraw.new();
        var b = storage.AcceptedOfferDraw.new();
        var c = storage.JobSheetCabinet.new();

        foreach(storagesystem; [a,b,c]) {
            storagesystem.clear()
        }
    },
    getNextJobSheet:  func(pilot) {
        # Returns a JobSheet describing the next job
        # :returns j: a jobsheet object 

        var fromAirport = funcs.getClosestAirport();
        var toAirport = nil;
        if (pilot.info.freight_market == 'short-haul') {
            toAirport = funcs.getRandNearAirport();
        }
        elsif (pilot.info.freight_market == 'long-haul') {
            toAirport = funcs.getLongHaulDestiAirport();
        }
        else {
            toAirport = funcs.getRandNearAirport();
        }

        var goods = funcs.getRandElementOfVector(constants.goodslist);
        var min_start_hour = funcs.getRandElementOfVector(constants.hourPdf);
        var min_start_secs = min_start_hour  * 60 * 60;
        var max_start_secs = min_start_secs + (60*60);

        var heading_and_dist = courseAndDistance(toAirport);
        var heading = heading_and_dist[0];
        var distance = heading_and_dist[1];

        var mkt = Market.new();

        var bpr = constants.basePayPerNm;
        var pay = mkt.calcPayRate(bpr, 
                                  distance, 
                                  pilot.weather.windSpeed, 
                                  pilot.weather.rainNorm, 
                                  min_start_hour);

        var jobstring = sprintf("Transport %s from %s (%s) to %s (%s). Depart asap after %d:00 hours. Heading: %d Distance: %.1f nm. Payment: %s%.2f", 
                                        goods, 
                                        fromAirport.name, 
                                        fromAirport.id,
                                        toAirport.name,
                                        toAirport.id,
                                        min_start_hour,
                                        math.round(heading),
                                        distance,
                                        funcs.getCurrency(),
                                        pay
                                        );

        var j = paperwork.JobSheet.new();
        j.status       = 'OFFER';
        j.fromId       = fromAirport.id;
        j.toId         = toAirport.id;
        j.fromName     = fromAirport.name;
        j.toName       = toAirport.name;
        j.heading      = heading;
        j.distance     = distance;
        j.goods        = goods;
        j.jobvalue     = pay;
        j.departafter  = min_start_secs; 
        j.departbefore = max_start_secs;

        return j;
    },
};
