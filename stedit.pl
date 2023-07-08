#!/usr/bin/perl
# perl script to call the StEdit.pm module
# so it can be easily used from a bash script
# the commands are passed by command line
# arguments to this script which then calls
# StEdit.pm methods

use strict;
use warnings;
use StEdit;
use Getopt::Std;

our ($opt_a, $opt_b, $opt_d, $opt_f, $opt_g, $opt_i, $opt_h, $opt_p, $opt_z);

# usage function
sub usage {
	print "stedit -f \"full pathname\" commands options\n";
	print "-a (append) \"text to append\"\n";
	print "-d (delete) \"pattern\" option -i case insensitive\n";
	print "-i (insert) \"text to insert\" option -p \"pattern\" -b (before- default) -z after -i case insensitive\n";
	print "-s (subst)  \"text to replace\" option -r \"replacement\" -i case insensitive -g global\n";
	print "-w (write)  \"new filename\"\n";
	print "-h (help)\n";
	exit 0;
}

###################################################
########### main entry
###################################################
# usage stedit options command options
# 1. -f filename to edit compulsory
# 2. commands
#             -a  (append): "string to append"
#             -d  (delete): "pattern"     options: -i case insensitive
#             -i  (insert): "text"        options: -p "pattern" -b before(default), -z after, -i case insensitive
#             -s  (subst) : "text"        options: -r "replacement" -i case insensitive, -g global
#             -w  (write) : "new file name"
#             -h  (help)

# check at least some arguments were given
my $count = scalar(@ARGV);

# invoke usage if no arguments given
usage if $count == 0;


# create the o
my $eobject = StEdit->new("/home/robert/junk.txt");
