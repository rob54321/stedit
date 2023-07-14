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
use lib "/mnt/ad64/stedit/usr/local/lib/site_perl";
use StEdit;
use Getopt::Std;

our ($opt_a, $opt_b, $opt_D, $opt_d, $opt_f, $opt_g, $opt_h, $opt_I, $opt_i, $opt_l, $opt_s, $opt_t, $opt_w, $opt_z);

# usage function
sub usage {
	print "use ANSI-C quoting \$'...' for interpolation of \\n etc in text arguments\n";
	print "stedit -f \"full pathname\" commands options\n";
	print "-d (delete) \"pattern\" option -i case insensitive\n";
	print "-a (append) \"text to append\" \n";
	print "-I (insert) \"pattern\" option -t \"text\" -b (before: default) -z after: -i case insensitive\n";
	print "-s (subst)  \"pattern\" option -r \"replacement\" -i case insensitive -g global\n";
	print "-w (write)  \"new filename\"\n";
	print "-l (list file)\n";
	print "-D (turn debugging on)\n";
	print "-h (help)\n";
	exit 0;
}
# this sub operates on the list @ARGV
# all the switches in the ARGV list are checked to see if they have arguments
# if they do not have arguments, the default arguments are inserted into ARGV
# so that getopts will not fail.
# no parameters are passed and none are returned.

sub defaultparameter {

	# hash supplying default arguments to switches
	# -b is for mounting bit locker drives
	# -v is for mounting vera containers
	# -u is for unmounting any drive
	# the default argument, if not given on the command line is all drives
	# the parameter "" cannot be used hence " " is used to indicate there is no filename
	my %defparam = ( -w => "");

	# for each switch in the defparam hash find it's index and insert default arguments if necessary
	foreach my $switch (keys(%defparam)) {
		# find index of position of -*
		my $i = 0;
		foreach my $param (@ARGV) {
			# check for a -b and that it is not the last parameter
			if ($param eq $switch) {
				if ($i < $#ARGV) {
					# -* has been found at $ARGV[$i] and it is not the last parameter
					# if the next parameter is a switch -something
					# then -* has no arguments
					# check if next parameter is a switch
					if ($ARGV[$i+1] =~ /^-/) {
						# -* is followed by a switch and is not the last switch
						# insert the 2 default filenames as a string at index $i+1
						my $index = $i + 1;
						splice @ARGV, $index, 0, $defparam{$switch};
					}
				} else {
					# the switch is the last in the list so def arguments must be appended
					my $index = $i + 1;
					splice @ARGV, $index, 0, $defparam{$switch}; 
				}
			}
			# increment index counter
			$i++;
		}
	}
} 

###################################################
########### main entry
###################################################
# usage stedit options command options
# 1. -f filename to edit compulsory
# 2. commands
#             -d  (delete): "pattern"     options: -i case insensitive
#             -a  (append): "string to append"
#             -I  (insert): "pattern"        options: -t "text" -b before(default), -z after, -i case insensitive
#             -s  (subst) : "pattern"        options: -r "replacement" -i case insensitive, -g global
#             -w  (write) : "new file name"
#             -l  (list)  : 
#             -h  (help)

# check at least some arguments were given
my $count = scalar(@ARGV);

# invoke usage if no arguments given
usage if $count == 0;

# for debugging
my $DEBUG = 0;

# get default parameter for -w if none was given
defaultparameter;

# getopts deletes ARGV, so save
# so it can be used for debugging
my @ORIGARGV = @ARGV;

# set default parameter for 
getopts ("a:bDd:f:ghI:ils:t:w:z");

# if -D is given turn on debugging
if ($opt_D) {
	$DEBUG = 1;
}

# for debugging
do {
	print "no of arguments " . scalar(@ORIGARGV) . "\n";
	foreach my $arg (@ORIGARGV) {
		print "param: " . $arg . ":\n";
	}
	print "#################\n";
} if $DEBUG;

# usage
if ($opt_h) {
	usage;
}

# create the editor instance
my $editor;
if ($opt_f) {
	# turn on debugging in StEdit.pm
	# pass $DEBUG flag to new
	$editor = StEdit->new($opt_f, $DEBUG);
} else {
	# no file specified
	die "stedit: A file name must be specifed to edit\n";
}

# delete function
# delete a line(s) that match pattern
# if no pattern is given, nothing is done
# parameters passed: pattern, optional -i modifier
# the -i modifier works with delete
if ($opt_d) {
	# delete may have modifier i
	my $modi = "";
	$modi = "i" if defined($opt_i);
	# rc is no lines deleted or undefined if an error occurred.
	my $count = $editor->delete($opt_d, $modi);
	print "stedit: Error deleting\n" unless defined($count);
}

# if append given
# note: if the string contains \n characters
# the bash ansi-c quoting $'...' must be used: eg. -a $'string\nnext line'
# must be used
# parameters passed: text
# no modifiers work with append
if ($opt_a) {
	my $rc = $editor->append($opt_a);
	print "stedit: Error appending to $opt_f\n" unless defined($rc);
}

# insert function
# text can be inserted before (default) or after each line
# where the pattern matches.
# also the pattern can be case (in)sensitive 
# stedit.pl modifiers -i case insensitive, -a insert after, -b insert before - default, work
# parameters passed: pattern, text, optional modifiers
if ($opt_I) {
	# error if no text given
	die "stedit: Insert error: no pattern/text given\n" unless $opt_t;

	# check which modifiers given
	my $modi = "";
	$modi = "a"         if defined($opt_z);
	$modi = $modi . "b" if defined($opt_b);
	$modi = $modi . "i" if defined($opt_i);

	# do insert, return from method is no of insertions
	my $count = $editor->insert($opt_I, $opt_t, $modi);	
	print "stedit: Error: inserting\n" unless defined($count);
}

# substitute a pattern with replacement text
# parameters passed: pattern, text replacement, optional modifiers -i -g
if ($opt_s) {
	# error if no text replacement
	die "stedit: Error: no text replacement given\n" unless $opt_t;

	# check which modifiers given
	my $modi = "";
	$modi = "i" if defined($opt_i);
	$modi = $modi . "g" if defined($opt_g);

	# do the substitution
	my $count = $editor->subst($opt_s, $opt_t, $modi);
	print "stedit: Error: substituting\n" unless defined($count);
}

# write the file to disk
# a file name may be "" whicn means the original file must be writtern to.
if (defined($opt_w)) {
	# write the file to disk
	# if no filename provided the default parameter is ""
	# which means use original file 
	$editor->write($opt_w);
}	

# display the file
# no title can be given
# StEdit.pm uses a title for debugging purposes only
if (defined($opt_l)) {
	# display the file
	# "" is the default parameter for -D switch
	# and means no title
	$editor->display();
}
