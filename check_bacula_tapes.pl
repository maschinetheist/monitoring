#!/usr/bin/perl
#
# Author:  Mike Pietruszka
# Date:    Mar 24, 2011
# Summary: Check the tape states in Bacula
#

use strict;
use warnings;

use Getopt::Long;
use Mysql;

my @errorvolumelist;
my $errorint = 0;
my $opthelp;

GetOptions(
    "help"         => \$opthelp,
);

if ($opthelp) {
    usage();
    exit 0;
}

# List of media
#my @mediaoutput = `echo "list media" | /usr/sbin/bconsole`;
#chomp @mediaoutput;

my $sqluser = "bacula";
my $sqlpasswd = "";
my $baculadb = "bacula";
my $dbserver = "DBI:mysql:database=$baculadb;host=localhost";
my $dbconn = DBI->connect($dbserver,$sqluser,$sqlpasswd) or die "Error connecting to: $dbserver: $DBI::errstr\n";

my $query = "SELECT VolumeName FROM bacula.Media WHERE VolStatus = \"Error\";";
my $sqlquery = $dbconn->prepare($query) or die "Error preparing statemeng", $dbconn->errstr;
$sqlquery->execute;
	
my @sqloutput;

while (@sqloutput = $sqlquery->fetchrow_array()) {
	foreach my $line(@sqloutput) {
		push(@errorvolumelist, $line);
		$errorint++;
	}
}

if ($errorint eq 0) {
	print "OK: Found $errorint volumes in \"Error\" state.\n";
	exit 0;
} elsif ($errorint gt 0) {
	my $badvolumes = join(", ", @errorvolumelist);
	print "Critical: Found $errorint volume(s) in \"Error\" state: ", $badvolumes, "\n";
	exit 2;
} else {
	print "Critical: Could not retrieve proper status of the tapes.\n";
	exit 3;
}

sub usage {
   	print "Small script that checks for any tapes in an \"Error\" state in Bacula.\n";
	print "Usage:\n";
	print "      --help          print this message and exit\n";
}

