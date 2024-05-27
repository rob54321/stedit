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
use lib "/home/robert/stedit/usr/local/lib/site_perl";
use cmdlOrder;

sub another {
	my $pm = shift;
	print "sub a with parameter $pm\n";
}

sub brady {
	print "sub b\n";
}

sub cleo {
	print "sub c\n";
}

sub dumbfries {
	my $pm = shift;
	print "sub d with parameter $pm\n";
}

my %subhash = ( -a => \&another,
             -b => \&brady,
             -c => \&cleo,
             -d => \&dumbfries);

# construct the object
my $control = cmdlOrder->new(\%subhash);

print @ARGV . "\n";
cmdlOrder->execsub(\@ARGV);
