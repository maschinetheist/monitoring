#!/usr/bin/perl
#
# Author:  Mike Pietruszka
# Date:    Mar 16, 2011
# Summary: Scan the filesystem for any volumes with abnormal size.
#
 
use strict;
use warnings;

use Getopt::Long;

# Levels
my $critical;
my $warning;
my $opthelp;
my @skipmountpoints;

# Volume level counts
my $warnvolcount = 0;
my $critvolcount = 0;
my $okvolcount = 0;

my %critvols;
my %warnvols;
my %okvols;

GetOptions(
	"critical|c=i" => \$critical,
	"warning|w=i"  => \$warning,
	"skip|s=s"	   => \@skipmountpoints,
	"help"         => \$opthelp,
);

if ($opthelp) {
	usage();
	exit 0;
}

if (!defined($warning) || !defined($critical)) {
	print "Unknown: missing required check parameters.  See --help for options\n";
	exit 3;
}

# File systems to monitor
open (PROC, "</proc/filesystems") or die "Cannot open /proc/filesystems\n";
my @procfs = grep (!/nodev/, <PROC>);
for (@procfs) {
	s/^\s+|\s+$//g;
}
my $fs = join("|", @procfs);
close (PROC);

my @target = `mount | tail -n +1`;
@target = grep (/$fs/, @target);

# Mechanism to allow us to skip volumes that we do not want included
foreach my $skipmountpoint(@skipmountpoints) {
	@target = grep (!/$skipmountpoint/, @target);
}

# Calculate the file system size
foreach my $target(@target) {
	my @mountpoint = split " ", $target;
	my $mountpoint;
	my $point = $mountpoint[0];	

	# Get size
	my ($fs_dev, $fs_type, $size, $used, $avail, $usage, $mount) = split(" ", `df -PT $point | tail -n +2`);
	$usage =~ s/\%//g;

	if ($usage > $critical) {
		$critvols{$mount} = "$usage";
		$critvolcount++;
	} elsif ($usage > $warning) {
		$warnvols{$mount} = "$usage";
		$warnvolcount++;
	} else {
		$okvols{$mount} = "$usage";
		$okvolcount++;
	}
}

# Get level
if ($critvolcount > 0) {
	print "CRITICAL: $critvolcount volume\(s\) with critical size: ";
	print join('; ', map "$_: $critvols{$_}%", keys %critvols) . "\n";
	exit 2;
} elsif ($warnvolcount > 0) {
	print "WARNING: $warnvolcount volume\(s\) with warning size: ";
	print join('; ', map "$_: $warnvols{$_}%", keys %warnvols) . "\n";
	exit 1;
} elsif ($okvolcount > 0) {
	print "OK: $okvolcount volume\(s\) with ok size: ";
	print join('; ', map "$_: $okvols{$_}%", keys %okvols) . "\n";
	exit 0;
} else {
	print "Critical: Could not retrieve proper partition size levels.\n";
	exit 2;
}

sub usage {
	print "Usage:\n";
	print "  -c, --critical=NUM  minimum NUM before considering a volume size critical\n";
	print "  -w, --warning=NUM   minimum NUM before considering a volume size warning\n";
	print "	 -s, --skip=STRING	 skip STRING mount point\n";
	print "      --help          print this message and exit\n";
}