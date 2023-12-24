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
# This file contains classes which help organize the data relating to the 
# state of the game. Two classes are defined: i) The JobSheet and 
# ii) the JobSheetBook
#
# The JobSheet class can be thought of as defining the core data structure 
# that this game uses to keep track of the game state.
#
# JobSheetBook is simply a collection of resolved (i.e. completed) jobsheets
# thus from it can be extracted a history of the jobs done and their outcomes 
# and costs and payments etc.


var JobSheet = {
    # The job sheet can be imagined as analogous to a form that the pilot 
    # receives from his or her office with details of the job to be done, the 
    # pilot then fills in some details (e.g. relating to departure time, 
    # starting fuel level etc). Once the job has concluded (either in a 
    # successful delivery or not) pilot updates the jobsheet and sends it to
    # the office who add some details such as costs incurred, payment amount 
    # etc and 'sign it off'
    new: func() {
        var m = { parents: [JobSheet] };
        # status should either be nil or:
        # 'OFFER'    => the office has offered the job to the pilot 
        # 'ACCEPTED' => the pilot has accepted the job
        # 'RESOLVED' => the job has concluded
        m.status = nil;
        m.fromId = nil; # the ICAO id of the from airport
        m.toId = nil;   # the ICAO id of the to airport
        m.fromName = nil; # name of the from airport
        m.toName = nil; # name of the to airport
        m.heading = nil; # heading from from airport to the to airport
        m.distance = nil; # distance from the from airport to the to airport
        m.goods = nil; # a string describing the type of goods to be transported
        m.jobvalue = nil; # the value assigned by the office to the job in GBP
        m.departafter = nil; #local time seconds (job must be accepted after this time)
        m.departbefore = nil; # local time seconds (job must be accepted before this time)
        m.actualstarttime = nil; #local time seconds (time accepted the job)
        m.startfuel_level_lbs = nil; # fuel in tanks when job accepted in lbs
        m.outcome_dist_todest = nil; #the distance to the destination at point of outcome in nm
        # the outcometype can take one of the following:
        # 'COMPLETED'     => means the goods were delivered (though not 
        #                    necessarily to the specified destination airport'
        # 'ABORTED_CRASH' => job aborted as a crash occurred
        # 'ABORTED_OTHER' => pilot chose to abort for some other reason
        m.outcometype = nil;
        m.outcometime = nil; #local time seconds (at outcome time)
        m.outcomefuel_level_lbs = nil; # fuel in tanks when job completed in lbs
        m.outcomeloc = nil ; #closest airport code
        m.fuelusage = nil; # difference between start and end fuel in lbs
        m.repaircosts = nil; # amount of repair expenses incurred in GBP
        m.fuelcosts = nil; # fuel costs incurred in GBP
        m.paymentrecieved = nil; # based on jobvalue and outcome, the payment received

        return m;
    },

    to_line: func() {
        # Serialises the jobsheet. Note any changes to this function require
        # corresponding changes to be made to the read_in_line function
        # and vis-a-versa
        #
        # :returns line: a string representation of the jobsheet object
        var line = (me.status                == nil ? '' : me.status)                ~ "||" ~ 
                   (me.fromId                == nil ? '' : me.fromId)                ~ "||" ~
                   (me.toId                  == nil ? '' : me.toId)                  ~ "||" ~
                   (me.fromName              == nil ? '' : me.fromName)              ~ "||" ~
                   (me.toName                == nil ? '' : me.toName)                ~ "||" ~
                   (me.heading               == nil ? '' : me.heading)               ~ "||" ~
                   (me.distance              == nil ? '' : me.distance)              ~ "||" ~
                   (me.goods                 == nil ? '' : me.goods)                 ~ "||" ~
                   (me.jobvalue              == nil ? '' : me.jobvalue)              ~ "||" ~
                   (me.departafter           == nil ? '' : me.departafter)           ~ "||" ~
                   (me.departbefore          == nil ? '' : me.departbefore)          ~ "||" ~
                   (me.actualstarttime       == nil ? '' : me.actualstarttime)       ~ "||" ~ 
                   (me.startfuel_level_lbs   == nil ? '' : me.startfuel_level_lbs)   ~ "||" ~
                   (me.outcome_dist_todest   == nil ? '' : me.outcome_dist_todest)   ~ "||" ~
                   (me.outcometype           == nil ? '' : me.outcometype)           ~ "||" ~ 
                   (me.outcometime           == nil ? '' : me.outcometime)           ~ "||" ~
                   (me.outcomefuel_level_lbs == nil ? '' : me.outcomefuel_level_lbs) ~ "||" ~
                   (me.outcomeloc            == nil ? '' : me.outcomeloc)            ~ "||" ~
                   (me.fuelusage             == nil ? '' : me.fuelusage)             ~ "||" ~
                   (me.repaircosts           == nil ? '' : me.repaircosts)           ~ "||" ~
                   (me.fuelcosts             == nil ? '' : me.fuelcosts)             ~ "||" ~
                   (me.paymentrecieved       == nil ? '' : me.paymentrecieved)       ~ "\n" ;
        return line;
    },

    read_in_line: func(line) {
        # Takes a serialised representation of a job sheet (as created by
        # the to_line function and un-serialises it, by setting the attributes
        # of this jobsheet object to values as indicated by the serialised
        # representation. Note any changes to this function require
        # corresponding changes to be made to the to_line function
        # and visa-versa
        #
        # :params line: a single line in the form as created by to_line 
        # :returns void
        data = split("||", line);
        me.status                = data[0]  == '' ? nil  : data[0];
        me.fromId                = data[1]  == '' ? nil  : data[1];
        me.toId                  = data[2]  == '' ? nil  : data[2];
        me.fromName              = data[3]  == '' ? nil  : data[3];
        me.toName                = data[4]  == '' ? nil  : data[4];
        me.heading               = data[5]  == '' ? nil  : data[5];
        me.distance              = data[6]  == '' ? nil  : data[6];
        me.goods                 = data[7]  == '' ? nil  : data[7];
        me.jobvalue              = data[8]  == '' ? nil  : data[8];
        me.departafter           = data[9]  == '' ? nil  : data[9];
        me.departbefore          = data[10] == '' ? nil  : data[10];
        me.actualstarttime       = data[11] == '' ? nil  : data[11];
        me.startfuel_level_lbs   = data[12] == '' ? nil  : data[12];
        me.outcome_dist_todest   = data[13] == '' ? nil  : data[13];
        me.outcometype           = data[14] == '' ? nil  : data[14];
        me.outcometime           = data[15] == '' ? nil  : data[15];
        me.outcomefuel_level_lbs = data[16] == '' ? nil  : data[16];
        me.outcomeloc            = data[17] == '' ? nil  : data[17];
        me.fuelusage             = data[18] == '' ? nil  : data[18];
        me.repaircosts           = data[19] == '' ? nil  : data[19];
        me.fuelcosts             = data[20] == '' ? nil  : data[20];
        me.paymentrecieved       = data[21] == '' ? nil  : data[21];
    },

    pretty_print_job: func() {
        # Returns a pretty formatted string describing the job as detailed in jobsheet
        # :returns r: a string
        var r = sprintf("Transport %s from %s (%s) to %s (%s). Depart asap after %d:00 hours. Heading: %d Distance: %.1f nm. Payment £%.2f", 
                            me.goods, 
                            me.fromName, 
                            me.fromId, 
                            me.toName, 
                            me.toId, 
                            funcs.getHourPartOfDaySecs(me.departafter),
                            math.round(me.heading),
                            me.distance,
                            me.jobvalue);
        debug.dump(r);
        return r;
    },

    pretty_print_outcome: func() {
        # Returns a pretty formatted string describing outcome of the job as 
        # detailed in the jobsheet
        # :returns outcomestr: a string
        var outcomestr = "";
        if((me.status == 'RESOLVED') and (me.outcometype == 'ABORTED_CRASH')) {
            outcomestr =" Job aborted due to crash. Net payment: " ~ sprintf("£%.2f", me.netpayment());
        }
        else if((me.status == 'RESOLVED') and (me.outcometype == 'ABORTED_OTHER')) {
            outcomestr = "Job aborted. Net payment: " ~ sprintf("£%.2f", me.netpayment());
        }
        else if((me.status == 'RESOLVED') and (me.outcometype == 'COMPLETED')) {
            outcomestr = me._pretty_print_completed_outcome();
        }
        return outcomestr;
    },
    # Calculates the net payment for the job. 
    # Should only be called once the job has been resolved
    # returns: a numeric value
    netpayment: func() {
        return me.paymentrecieved - me.fuelcosts - me.repaircosts;
    },

    _pretty_print_completed_outcome: func() {
        var outcomestr = "";
        var hrs  = funcs.getHourPartOfDaySecs(me.outcometime);
        var mins = funcs.getMinsPartOfDaySecs(me.outcometime);

        if((me.status == 'RESOLVED') and (me.outcometype == 'COMPLETED')) {
            if(me.outcomeloc == me.toId) {
                var r1= "Goods delivered to " ~ me.outcomeloc ~ " at: " ~ hrs ~ ":" ~ mins ~ " hours.";
                var r2= "Net payment: " ~ sprintf("£%.2f", me.netpayment());
                outcomestr = r1 ~ " " ~ r2; 
            }
            else {
                var r1 = "You diverted to " ~ me.outcomeloc ~ " and the goods have been unloaded";
                var r2 = "here rather than at " ~ me.toId  ~ "." ;
                var r3 = "Time: " ~ hrs ~ ":" ~ mins ~ " hours. Net payment: " ~ sprintf("£%.2f", me.netpayment());
                outcomestr = r1 ~ " " ~ r2 ~ " " ~ r3; 
            }
        }
        return outcomestr;
    },
};


var JobSheetBook = {
    # JobSheetBook is simply a collection of resolved ( completed) jobsheets
    # thus from it can be extracted a history of the jobs done, outcomes 
    # and costs and payments etc.
    new: func(vector_of_jobsheets) {
    # :params vector_of_jobsheets: a vector containing jobsheet objects
    #  note all the jobsheet objects should be resolved (complete)
    #  i.e. not partial jobsheets
        var m = { parents: [JobSheetBook] };
        m.book_of_jobsheets = vector_of_jobsheets;
        return m;
    },
    num_of_jobsheets_in_book: func() {
        # return cost in GBP of ammount of fuel as given by lbs
        return size(me.book_of_jobsheets); 
    },
    running_balance: func() {
        # Iterates through the jobsheets calculating the netpayment (payment
        # minis expences) for each job and sums them up into a balance
        var balance = 0.0;
        if(me.num_of_jobsheets_in_book() > 0) {
            foreach(js; me.book_of_jobsheets) {
                 balance = balance + js.netpayment();
            }
        }
        return balance;
    },
    describe: func() {
        # Returns a nicely formatted string describing the running totals re
        # the jobs carried out to date
        return sprintf("%d jobs carried out to date. Net profit running total:  £%.2f", me.num_of_jobsheets_in_book(), me.running_balance());
    },
};


