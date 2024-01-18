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
# This file functions that are called from addon-menu-items.xml
# so can be thought of as being the interface with the user.

var aboutHighAirTrader = func() {
    var str1 = "HighAirTrader (Version 0.4.1)";
    var str2 = "Developed by Peter Clifton and Thomas Clifton (2023).";
    return str1 ~ " " ~ str2;
}

var markJobComplete = func() {
    # Intended to be called when the user indicates they have arrived 
    # as the destination airport. If game conditions permit will
    # populate the jobsheet and store the record
    #
    # :returns a text string that can be displayed to the user
    var storageDir = constants.storagedirpath;
    var feedbackstring = "No current job!";

    var ao_draw = storage.AcceptedOfferDraw.new();
    if(getprop("/sim/aircraft") == "ufo" or getprop("/sim/aircraft") == "bluebird") {
        feedbackstring = "Aircraft not possible";
    }
    else if(funcs.negligibleGroundSpeed() == 0) {
        feedbackstring = "Aircraft still moving - please come to a stop first";
    }
    else if(funcs.brokenGearDetected() == 1) {
        feedbackstring = "Aircraft is damaged - please report crash to office";
    }
    else if(ao_draw.contains_acceptedoffer()) {

        var pilot = world.Pilot.new();
        var maintenancemanager = world.MaintenanceManager.new();
        var office = world.Office.new();

        var jS = paperwork.JobSheet.new();
        jS.read_in_line(ao_draw.view());
        ao_draw.clear();

        jS = pilot.enter_outcome_details_jobcomplete(jS);
        jS = maintenancemanager.populate_maintenance_section(jS);
        jS = office.signoff_jobsheet(jS); 

        var jScabinet = storage.JobSheetCabinet.new();
        jScabinet.put(jS.to_line());

        feedbackstring = jS.pretty_print_outcome();
        setprop("/sim/highairtrader/configs/mission", 0);
    }
    return feedbackstring;
}

var markJobAbortedDueCrash = func() {
    # Intended to be called when the user indicates they have crashed
    # during the delivery attempt, If game conditions permit will
    # populate the jobsheet and store the record
    #
    # :returns a text string that can be displayed to the user
    var storageDir = constants.storagedirpath;
    var result = "No current job!";

    var ao_draw = storage.AcceptedOfferDraw.new();
    if(ao_draw.contains_acceptedoffer()) {

        var pilot = world.Pilot.new();
        var maintenancemanager = world.MaintenanceManager.new();
        var office = world.Office.new();

        var jS = paperwork.JobSheet.new();
        jS.read_in_line(ao_draw.view());
        ao_draw.clear();

        jS = pilot.enter_outcome_details_aborted_crash(jS);
        jS = maintenancemanager.populate_maintenance_section(jS);
        # Office puts paymentrecieved amount on the jobsheet: 
        jS = office.signoff_jobsheet(jS);

        var jScabinet = storage.JobSheetCabinet.new();
        jScabinet.put(jS.to_line());
        result = jS.pretty_print_outcome();
        setprop("/sim/highairtrader/configs/mission", 0);
    }
    return result; 
}

var markJobAbortedDueOther = func () {
    # Intended to be called when the user indicates they have aborted 
    # the delivery attempt (for reason other than a crash), If game 
    # conditions permit will populate the jobsheet and store the record
    #
    # :returns a text string that can be displayed to the user
    var storageDir = constants.storagedirpath;
    var feedbackstring = "No current job!";
    var ao_draw = storage.AcceptedOfferDraw.new();

    if(funcs.negligibleGroundSpeed() == 0) {
        feedbackstring = "Aircraft still moving - please come to a stop first";
    }
    else if(funcs.brokenGearDetected() == 1) {
        feedbackstring = "Aircraft is damaged - please report crash to office";
    }
    else if(ao_draw.contains_acceptedoffer()) {

        var pilot = world.Pilot.new();
        var maintenancemanager = world.MaintenanceManager.new();
        var office = world.Office.new();

        var jS = paperwork.JobSheet.new();
        jS.read_in_line(ao_draw.view());
        ao_draw.clear();

        jS = pilot.enter_outcome_details_aborted_other(jS);
        jS = maintenancemanager.populate_maintenance_section(jS);
        # Office puts paymentrecieved amount on the jobsheet: 
        jS = office.signoff_jobsheet(jS); 

        var jScabinet = storage.JobSheetCabinet.new();
        jScabinet.put(jS.to_line());
        feedbackstring = jS.pretty_print_outcome();
        setprop("/sim/highairtrader/configs/mission", 0);
    }
    return feedbackstring;
}

var getNextJob = func() {
    # Intended to be called when the user requests a new job
    # If game conditions permit will get a new joboffer and
    # save its details (as a pending offer)
    #
    # :returns a text string describing the offer that can be displayed to the user
    var feedbackstring = "";
    var ao_draw = storage.AcceptedOfferDraw.new();

    if(ao_draw.contains_acceptedoffer()) {
        feedbackstring = "Existing job must be resolved first!";
    }

    else if(funcs.negligibleGroundSpeed() == 0) {
        feedbackstring = "Aircraft still moving - please come to a stop first";
    }
    else {
        var pilot = world.Pilot.new();
        debug.dump(pilot.info);
        debug.dump(pilot.weather);
        var offerJobSheet = world.Office.new().getNextJobSheet(pilot);
        var draw = storage.PendingOfferDraw.new();

        draw.put(offerJobSheet.to_line());
        feedbackstring = offerJobSheet.pretty_print_job();
    }
    return feedbackstring;
}

var viewPendingOffer = func() {
    # Intended to be called when the user requests to view the
    # current pending offer. If game conditions permit will get a 
    # description of the current offer that can be displayed to the user.
    #
    # :returns a text string describing the offer that can be displayed to the user
    var prettyprint_po_string = "No pending job offers";
    var draw = storage.PendingOfferDraw.new();

    if(draw.contains_pendingoffer()) {
        var jS = paperwork.JobSheet.new();
        jS.read_in_line(draw.view());
        var prettyprint_po_string = jS.pretty_print_job();
    }
    return prettyprint_po_string;
}

var viewCurrentJob = func() {
    # Intended to be called when the user requests to view the
    # current job. If game conditions permit will get a 
    # description of the current job that can be displayed to the user.
    #
    # :returns a text string describing the current job
    var prettyprint_cj_string = "No current job";
    var draw = storage.AcceptedOfferDraw.new();

    if(draw.contains_acceptedoffer()) {
        var jS = paperwork.JobSheet.new();
        jS.read_in_line(draw.view());
        var prettyprint_cj_string = jS.pretty_print_job();
    }
    return prettyprint_cj_string;
}

var acceptPendingOffer = func() {
    # Intended to be called when the user indicates that they are accepting
    # the current pending offer. If game conditions permit will
    # update the jobsheet accordingly and the pending offer will now
    # become the 'accepted offer' or 'current job'
    #
    # :returns a text string saying that the job has been accepted etc
    var feedbackstring = "";
    var draw = storage.PendingOfferDraw.new();
    var ao_draw = storage.AcceptedOfferDraw.new();

    if(getprop("/sim/aircraft") == "ufo" or getprop("/sim/aircraft") == "bluebird") {
        feedbackstring = "Aircraft not possible";
    }
    else if(ao_draw.contains_acceptedoffer()) {
        feedbackstring = "Existing job must be resolved first!";
    }
    else if(funcs.negligibleGroundSpeed() == 0) {
        feedbackstring = "Aircraft still moving - please come to a stop first";
    }
    else if(draw.contains_pendingoffer()) {
        var pendofferstring = draw.view();      
        var j = paperwork.JobSheet.new();
        j.read_in_line(pendofferstring);

        # Check that we are still at the same airport as the pending offder 'from' 
        # airport before allowing the job to be accepted
        if(j.get_fromId() == funcs.getClosestAirportId()) { 
            # we are still at the same airport, so the pending offer will get turned
            # into the live job.
            
            # first empty the pending offer draw (the job sheet will get put in the 
            # accepted offer draw):
            draw.clear();  

            # rest of job acceptance admin:
            var pilot = world.Pilot.new();
            j = pilot.enter_accept_pending_offer_details(j);
            ao_draw.put(j.to_line());
            var fbs1 = "Pending job offer accepted! ";
            var fbs2 = "Transport goods to destination and update office upon arrival";
            feedbackstring = fbs1 ~ fbs2; 
            setprop("/sim/highairtrader/configs/mission", 1);
       }
       else { # we are not at the same airport as the pending offer's 'from' airport:
           feedbackstring = "You must be at " ~ j.get_fromId() ~ " to start this job";
       }
    }
    else { # i.e. file does not exist or is zero size
        feedbackstring = "No pending job offers";
    }
    return feedbackstring;
}

var reset_game = func() {
    # Caution - will wipe all saved HighAirTrader data!
    # Intended to be called when the user asks to delete all the 
    # saved game data. Deletes all the saved info, ie:
    # jobsheet records, pending offer, current accepted offer.
    #
    # :returns void
    var office = world.Office.new();
    office.shred_all_paperwork();
}

var get_perf_summary = func() {
    # Intended to be called when the user asks for an update on
    # their delivery performance todate. Looks over the resolved jobsheets
    # and calculates works out the number of jobs done and current
    # running total profit.
    #
    # :returns a text string with info for the user
    var office = world.Office.new();
    return office.get_peformance_summary();
}

# --HELPER FUNCTIONS-----------------------------------------------------------

# --end of helper functions----------------------------------------------------

# --- DEBUGGING ---------------------------------------------------------------

# Use the below function to debg stuff when doing development

#var debugtester = func() {
#    var foo = "Something";
#    debug.dump(foo); # this will output "Something" to the conole
#    return foo;
#}

# --- end of debugging section ------------------------------------------------

#---Misc notes ----------------------------------------------------------------
# https://wiki.flightgear.org/Nasal_library/io#stat.28.29

