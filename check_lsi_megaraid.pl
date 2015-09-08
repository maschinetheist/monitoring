#!/usr/bin/perl
#
# Author:  Mike Pietruszka
# Date:    Feb 13th, 2012
# Summary: Check LSI MegaRAID status
#

use strict;
use warnings;

# Nagios/Zenoss Return Codes
my $ok = 0;
my $warning = 1;
my $critical = 2;
my $unknown = 3;

my $arraystatus;
my $batterystatus;
my @statusmessage;

# MegaCLI executable and flags
my $megaclibinary = "/opt/MegaRAID/CLI/MegaCli";
my $megaclioutput = "megastatus.txt";
my $megavdrivenum = "-LDGetNum -aALL";
my $megalogicalinfo = "-LDInfo -L0 -aALL";
my $megabattflag = "-AdpBbuCmd -aALL";


# Sanity checks
#
# Check if we are running under elevated privileges
if ($< != 0) {
    print "Script must be run under elevated privileges.\n";
    exit 1;
}

# Check if MegaCli binary exists
if (! -e $megaclibinary) {
    print "MegaCli executable is missing.\n";
    exit 1;
}


# Main logic
#
# Get the number of logical/virtual drives
my $numofvdrives = `$megaclibinary $megavdrivenum`;
chomp($numofvdrives);
$numofvdrives =~ s/Number of Virtual Drives Configured on Adapter 0: //g;
$numofvdrives =~ s/Exit Code: 0x0[0-9]//g;
$numofvdrives =~ s/^\s+$//g;

# Gather the status information for each logical/virtual drive
my %vdrives;

# Since virtual drives IDs start at 0, we'll increment
my $vdrivecounter = 0;
while ($vdrivecounter < $numofvdrives) {
    my @logdriveinfo = `$megaclibinary -LDInfo -L$vdrivecounter -aALL`;
    my $tempvdrive;
    chomp(@logdriveinfo);
    # Get the drive's ID and state; dump into a hash
    foreach my $logdriveinfo (@logdriveinfo) {
        for (grep (/Target Id:/, $logdriveinfo)) {
            $tempvdrive = $logdriveinfo;
        }
        for (grep (/State/, $logdriveinfo)) {
            s/State\s+/State/g;
            $vdrives{$tempvdrive} = $logdriveinfo;
        }
    }
    # Increment the 0 so we're n-1 where n = total number of drives
    $vdrivecounter++;
}


# Determine the virtual drives' states
while ((my $vdrive, my $vdrivestate) = each(%vdrives)) {
    if (grep (/Optimal/, $vdrivestate)) {
        $arraystatus = "OK";
        my $vdrivestatus = "$vdrive $vdrivestate";
        push(@statusmessage, $vdrivestatus);
    } else {
        $arraystatus = "CRITICAL";
        my $vdrivestatus = "$vdrive $vdrivestate";
        push(@statusmessage, $vdrivestatus);
        last;
    }
}

# Determine the battery state
my @megabattoutput = `$megaclibinary $megabattflag`;
chomp(@megabattoutput);

foreach my $megabattoutput (@megabattoutput) {
    for (grep (/Battery State/, $megabattoutput)) {
        s/State\s+:/State:/g;
        if (grep (/Operational|Optimal/, $megabattoutput)) {
            $batterystatus = "OK";
            push(@statusmessage, $megabattoutput);
        } else {
            $batterystatus = "CRITICAL";
            push(@statusmessage, $megabattoutput);
        }
    }
}


# Print out the Nagios/Zenoss status
if (($arraystatus eq "CRITICAL") or ($batterystatus eq "CRITICAL"))  {
    print "CRITICAL: ";
    print join ('; ', @statusmessage) . "\n";
    exit $critical;
} elsif (($arraystatus eq "OK" ) and ($batterystatus eq "OK")) {
    print "OK: ";
    print join ('; ', @statusmessage) . "\n";
    exit $ok;
} else {
    print "UNKNOWN\n";
    exit $unknown;
}
