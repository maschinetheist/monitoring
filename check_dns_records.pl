#!/usr/bin/perl
#
# Author:  Mike Pietruszka
# Date:    Mar 25, 2011
# Summary: Check for PTR records against a DNS forward zone vice versa.
#

use strict;
use warnings;

use Getopt::Long;

my $forwardfile;
my $reversefile;
my $opthelp;

GetOptions(
    "forward|f=s"  => \$forwardfile,
    "reverse|r=s"  => \$reversefile,
    "help"         => \$opthelp,
);

if ($opthelp) {
    usage();
    exit 0;
}

if (!defined($forwardfile) || !defined($reversefile)) {
    print "Unknown: missing required check parameters.  See --help for options\n";
    exit 3;
}

my @missingptr;
my @missinga;

open (AHANDLE, "< $forwardfile") or die "$forwardfile cannot be opened.\n";
open (PTRHANDLE, "< $reversefile") or die "$reversefile cannot be opened.\n";

my @arecords = grep(/IN.*\sA/, <AHANDLE>);
my @ptrrecords = grep(/PTR/, <PTRHANDLE>);

foreach my $arecords(@arecords) {
	$arecords =~ s/(^;.*|^\*.+$)//gs;
	$arecords =~ s/^\n//gs;
	
	# Split each line in A zone file into an array
	my @arecordline = split(' ', $arecords);

	# Check each A zone line for a PTR record
	foreach my $arecordline($arecordline[0]) {
		if (defined($arecordline)) {
			if (! grep(/$arecordline/, @ptrrecords)) {
			    push(@missingptr, $arecordline);
			}
		}
	}
}

foreach my $ptrrecords(@ptrrecords) {
    $ptrrecords =~ s/(^;.*|\.domain\.com\.|^\*.+$)//gs;
    $ptrrecords =~ s/^\n//gs;
    
	my @ptrrecordline = split(' ', $ptrrecords);

    foreach my $ptrrecordline($ptrrecordline[3]) {
        if (defined($ptrrecordline)) {
            if (! grep(/$ptrrecordline/, @arecords)) {
            	push(@missinga, $ptrrecordline);
			}
		}
    }
}

print "Found ", scalar(@arecords), " A records in $forwardfile.\n";
print "Found ", scalar(@ptrrecords), " PTR records in $reversefile.\n";
print "\n";
print "Missing ", scalar(@missingptr), " PTR records:\n";
print "-----------------------\n";
foreach (@missingptr) {
	print "$_\n";
}
print "\n";
print "Missing ", scalar(@missinga), " A records:\n";
print "-----------------------\n";
foreach (@missinga) {
	print "$_\n";
}

close (AHANDLE);
close (PTRHANDLE);

sub usage {
    print "Usage:\n";
    print "  -f, --forward      forward DNS zone file\n";
    print "  -r, --reverse      reverse DNS zone file\n";
    print "      --help         print this message and exit\n";
}

