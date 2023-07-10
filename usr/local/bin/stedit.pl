#!/usr/bin/perl
# perl script to call the StEdit.pm module
# so it can be easily used from a bash script
# the commands are passed by command line
# arguments to this script which then calls
# StEdit.pm methods

# use bash ANSI-C quoting when interpolation of \n \r etc are required
# stedit.pl -a $'oneline\nlast line\n'
# format is $'...'

use strict;
use warnings;
use StEdit;
use Getopt::Std;

our ($opt_a, $opt_b, $opt_d, $opt_f, $opt_g, $opt_i, $opt_h, $opt_p, $opt_z);

# usage function
sub usage {
	print "use ANSI-C quoting \$'...' for interpolation of \\n etc in text arguments\n";
	print "stedit -f \"full pathname\" commands options\n";
	print "-a (append) \"text to append\" \n";
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
# for debugging
my $DEBUG = 1;

do {
	foreach my $arg (@ARGV) {
		print "param: " . $arg . ":\n";
	}
} if $DEBUG;

getopts ("a:bd:f:ghip:s:w:z");
# invoke usage if no arguments given
usage if $count == 0;


# create the editor instance
my $editor;
if ($opt_f) {
	$editor = StEdit->new($opt_f);
} else {
	# no file specified
	die "A file name must be specifed to edit\n";
}

# if append given
# note: if the string contains \n characters
# the bash ansi-c quoting $'...' must be used: eg. -a $'string\nnext line'
# must be used
if ($opt_a) {
	my $rc = $editor->append($opt_a);
	print "Error appending to $opt_f\n" unless $rc == 1;
}

# delete function
if ($opt_d) {
	# delete may have modifier i
	my $modi = "";
	$modi = "i" if defined($opt_i);
	# rc is no lines deleted or -1 if an error occurred.
	my $rc = $editor->delete($opt_d, $modi);
	die "Error deleting\n" if $rc == -1;
}
