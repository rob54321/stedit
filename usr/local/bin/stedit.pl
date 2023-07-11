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

our ($opt_a, $opt_b, $opt_d, $opt_f, $opt_g, $opt_h, $opt_I, $opt_i, $opt_s, $opt_t, $opt_w, $opt_z);

# usage function
sub usage {
	print "use ANSI-C quoting \$'...' for interpolation of \\n etc in text arguments\n";
	print "stedit -f \"full pathname\" commands options\n";
	print "-d (delete) \"pattern\" option -i case insensitive\n";
	print "-a (append) \"text to append\" \n";
	print "-I (insert) \"pattern\" option -t \"text\" -b (before: default) -z after: -i case insensitive\n";
	print "-s (subst)  \"pattern\" option -r \"replacement\" -i case insensitive -g global\n";
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
#             -d  (delete): "pattern"     options: -i case insensitive
#             -a  (append): "string to append"
#             -I  (insert): "pattern"        options: -t "text" -b before(default), -z after, -i case insensitive
#             -s  (subst) : "pattern"        options: -r "replacement" -i case insensitive, -g global
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

getopts ("a:bd:f:ghI:is:t:w:z");
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
	if (defined($count)) {
		print "$count lines deleted\n" if $DEBUG;
	} else {
		print "Error deleting\n";
	}
}

# if append given
# note: if the string contains \n characters
# the bash ansi-c quoting $'...' must be used: eg. -a $'string\nnext line'
# must be used
# parameters passed: text
# no modifiers work with append
if ($opt_a) {
	my $rc = $editor->append($opt_a);
	print "Error appending to $opt_f\n" unless defined($rc);
}

# insert function
# text can be inserted before (default) or after each line
# where the pattern matches.
# also the pattern can be case (in)sensitive 
# modifiers -i case insensitive, -a insert after, -b insert before - default, work
# parameters passed: pattern, text, optional modifiers
if ($opt_I) {
	# error if no text given
	die "Error: no text to insert given\n" unless $opt_t;

	# check which modifiers given
	my $modi = "";
	$modi = "a"         if defined($opt_z);
	$modi = $modi . "b" if defined($opt_b);
	$modi = $modi . "i" if defined($opt_i);

	# a and b are mutually exclusive
	# print an error and do nothing
	if ($modi =~ /ab/) {
		 print "Error: -z (after) and -b (before) are mutually exclusive\n";
	} else {
		# print $modi
		print "modifier = $modi\n" if $DEBUG;
	
		# do insert, return from method is no of insertions
		my $count = $editor->insert($opt_I, $opt_t, $modi);	
		if (defined($count)) {
			print "$count insertions\n" if $DEBUG;
		} else {
			print "Error: inserting\n";
		}
	}
}
