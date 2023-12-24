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
# This file contains classes to facilitate saving and loading game state info
# from the file system.


# MODULE LEVEL VARIABLES-------------------------------------------------------
var secondPartOfPath = "/Export/Addons/org.flightgear.addons.HighAirTrader/";
var storagedirpath = getprop("/sim/fg-home") ~ secondPartOfPath;

# CLASSES----------------------------------------------------------------------

var GenericStorage = {
    # A prototype class intended to be used as a parent class by other classes 
    # that save and or load game info from the file.
    new: func() {
        # Note: there is no filepath attribute here yet, but me.filepath is 
        # referred to by functions in this class. The more concrete descendent 
        # classes will instantiate the filepath attribute.
        var m = { parents: [GenericStorage] };
        return m;
    },
    contains_something: func() {
        # The storage device is considered to contain something if the 
        # file associated with the storage device exists and has a non
        # zero file size.
        #
        # :returns result: a boolean, 1 if the storage contains something else 0
        var result = 0;
        var stat = io.stat(me.filepath);
        if((stat!=nil) and (stat[7]!=0) ) { #stat[7] is the file size in bytes
            result = 1;
        }
        return result;
    },
    clear: func() {
        # Clears the info from the storage device, by clobbering the file
        # associated with the storage device if said file exits
        #
        # returns: void
        var stat = io.stat(me.filepath);
        if((stat!=nil) and (stat[7]!=0) ) { 
            var file = io.open(me.filepath,"w"); # clobbers the file
            io.close(file);
        }
    },
};

var GenericDraw = {
    # A prototype class intended to be used as a parent class by other classes 
    # that save and or load game info from a file that contains
    # a max of 1 line of data. 
    new: func() {
        # Note: there is no filepath attribute here yet, but me.filepath is 
        # referred to by functions in this class. The more concrete descendent 
        # classes will instantiate the filepath attribute.
        var m = { parents: [GenericDraw, GenericStorage.new()] };
        return m;
    },
    put: func(line) {
        # Writes a single line of data to the file, overwriting any existing 
        # contents of the file.
        # :param line: a single line of text
        # :returns void

        # Creates a new file for output (writing). If file already exists, 
        # its contents will be cleared first.
        var file = io.open(me.filepath,"w"); 
        io.write(file, line);
        io.close(file);
    },
    view: func() {
        # Fetches the line in the file and returns it
        # If the file is empty or does not exist will return an empty string
        # :return pendingofferstring: string
        var pendingofferstring = "";
        var stat = io.stat(me.filepath);

        if((stat!=nil) and (stat[7]!=0) ) { #stat[7] is the file size in bytes
            var file = io.open(me.filepath,"r");
            pendingofferstring = io.readln(file);
            io.close(file);
        }
        else { # i.e. file does not exist or is zero size
            pendingofferstring = ""; 
        }
        return pendingofferstring;
    }
};

var GenericCabinet = {
    # A prototype class intended to be used as a parent class by other classes 
    # that save and or load game info from a file that may contains
    # multiple lines of data. 
    new: func() {
        # Note: there is no filepath attribute here yet, but me.filepath is 
        # referred to by functions in this class. The more concrete descendent 
        # classes will instantiate the filepath attribute.
        var m = { parents: [GenericCabinet, GenericStorage.new()] };
        return m;
    },
    put: func(line) {
        # Writes a single line of data to the file. If the file already exists
        # this new line will be appended at the end of the file.
        # :param line: a single line of text
        # :returns void

        # Opens a file for appending data. File created if does not exist.
        var file = io.open(me.filepath,"a"); 
        io.write(file, line);
        io.close(file);
    },
    view: func() {
        # View the contents of the 'cabinet'
        # Depends on the data in the file being organised in rows and there not
        # being any empty rows. i.e. each row should be able to be red properly
        # by JobSheet.read_in_line Note as split will return an empty string 
        # after the last \n we use slicing i.e. [:-2] to exclude the last 
        # element of the vector (which would just be an empty string)
        #
        # :returns a vector each element being a row of text from the cabinet
        #  empty vector returned if cabinet empty
        var cabinet_contents = [];
        if(me.contains_something()) {
            var filestring = io.readfile(me.filepath);
            cabinet_contents = split("\n", filestring)[:-2];
        }
        return cabinet_contents;
    },
};

var PendingOfferDraw = {
    # A specific implementation of a draw. This class is specifically to
    # provide an interface to the file where the string representing the 
    # current pending offer is stored to or is to be stored.
    # I.e. a PendingOfferDraw object can be used to save a string
    # representing the pending offer, check if a pending offer 
    # exists, and read the current pending offer.
    new: func() {
        var m = { parents: [PendingOfferDraw,GenericDraw.new() ] };
        m.filepath = storagedirpath ~ 'pendingoffer.txt';
        return m;
    },
    viewpendingoffer: func() {
        var r = me.view();
        return r == "" ? "No pending job offers" : r;
    },
    contains_pendingoffer: func() {
        # :returns a boolean, 1 if the storage contains something else 0
        return me.contains_something();
    },
};

var AcceptedOfferDraw = {
    # A specific implementation of a draw. This class is specifically to
    # provide an interface to the file where the string representing the 
    # current accepted offer is stored to or is to be stored.
    # I.e. a AcceptedOfferDraw object can be used to save a string
    # representing the current job, check if there exists a current job
    # and read the current pending job from the file.
    new: func() {
        var m = { parents: [AcceptedOfferDraw,GenericDraw.new()] };
        m.filepath = storagedirpath ~ 'acceptedoffer.txt';
        return m;
    },
    viewacceptedoffer: func() {
        var r = me.view();
        return r == "" ? "No pending job offers" : r;
    },
    contains_acceptedoffer: func() {
        # :returns a boolean, 1 if the storage contains something else 0
        return me.contains_something();
    },
};

var JobSheetCabinet = {
    # A specific implementation of a cabinet. This class is specifically to
    # provide an interface to the file where one line represents one 
    # completed (resolved jobsheet)
    # I.e. a JobSheetCabinet object can be used to save another job sheet or to
    # read the contents currently saved in the cabinet.
    new: func() {
        var m = { parents: [JobSheetCabinet, GenericCabinet.new()] };
        m.filepath = storagedirpath ~ 'chronoLog.txt';
        return m;
    },
    view_jobsheet_book: func() {
        # Gets the jobsheets from the JobSheetCabinet
        # :returns a vector of jobsheet objects
        var vector_of_jobsheets = [];
        var raw_jobsheet_book = me.view();
        foreach(jobsheetstring; raw_jobsheet_book) {
            var jS = paperwork.JobSheet.new();
            jS.read_in_line(jobsheetstring);
            append(vector_of_jobsheets, jS);
        }
        return vector_of_jobsheets;
    },
};
