#!/usr/bin/perl
use strict;
use Getopt::Long;

###################
# arguments

my $mac_string;
my $rrd_dir;

GetOptions(
	"b=s"=>\$mac_string,
        "r=s"=>\$rrd_dir
);

die("no valid address given") unless (length($mac_string) == 17);
my @mac = split(substr($mac_string, 2, 1), $mac_string);
die("no valid address given") unless (@mac == 6);

die("no valid rrd directory given") unless (-e $rrd_dir);

my $rrdfile_temp = $rrd_dir . "/" . join("", @mac) . "_temp.rrd";
my $rrdfile_tdew = $rrd_dir . "/" . join("", @mac) . "_tdew.rrd";
my $rrdfile_rh   = $rrd_dir . "/" . join("", @mac) . "_rh.rrd";
my $rrdfile_bat  = $rrd_dir . "/" . join("", @mac) . "_bat.rrd";
my $updatefile   = $rrd_dir . "/" . "update.sh";

my $lastupdate;

###################
# functions

sub log10 {
	my $n = shift;
	return log($n)/log(10);
}

###################
# main

# check last updated date
open (PIPE, "rrdtool info $rrdfile_temp|");
while (<PIPE>)
{
	if (/^last_update = (\d*)$/)
	{
		$lastupdate = $1;
	}

}
close (PIPE);

# open file for rrd update commands
open (FILE, ">", "$updatefile");

# get battery level
open (PIPE, "/usr/bin/timeout 45 /usr/local/bin/gatttool -b " . join(":", @mac) . " --char-read --handle=0x002b|");

while (<PIPE>)
{
	chomp;
	chomp;

	if (/^Characteristic value\/descriptor: ([0-9A-Fa-f]{2})\s*$/)
	{
		my $battery_level = hex($1);

		printf ("battery level: %d%\n", $battery_level);
		printf FILE "rrdtool update %s %d:%d\n", $rrdfile_bat, time(), $battery_level;
	}
}

close (PIPE);

# get temperature and humidity values
open (PIPE, "/usr/bin/timeout 45 /usr/local/bin/gatttool -b " . join(":", @mac) . " --char-write-req --handle=0x0026 --value=0100 --listen|");

my $data_count = 0;

while (<PIPE>)
{
	chomp;
	chomp;

	if (/^Notification handle = 0x0025 value: ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2}) 01 ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})\s*$/)
	{
		my ($count, $temperature, $humidity) = (hex($1.$2), hex($3)-40, hex($4));

		# dewpoint calculation
		my $a = 7.5;
		my $b = 237.3;
		if ($temperature < 0)
		{
			$a = 7.6;
			$b = 240.7;
		}
		my $v = log10( $humidity / 100 * (10 ** (($a*$temperature)/($b+$temperature))) );
		my $tdew = $b*$v / ($a-$v);

		# time calculation
		my $time = time() - ($count-1) * 300;
		$time = $time - ($time % 300);

		my $datestring = localtime($time);

		printf "%3d: [%s] %2d.C %2d%rH | %02.1f.C", $count, $datestring, $temperature, $humidity, $tdew;
	
		if ($time > $lastupdate)
		{	
			print " +";
			printf FILE "rrdtool update %s %d:%d\n", $rrdfile_temp, $time, $temperature;
			printf FILE "rrdtool update %s %d:%d\n", $rrdfile_rh,   $time, $humidity;
			printf FILE "rrdtool update %s %d:%f\n", $rrdfile_tdew, $time, $tdew;
		}
		
		print "\n";
		
		$data_count = $data_count + 1;

		#close (PIPE) if ($count == 1);

	}
	else
	{
		#print ("? $_\n");
	}
}
close (PIPE);

close (FILE);

printf ("received %d points\n", $data_count);
