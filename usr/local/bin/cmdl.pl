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

# hash for cmdlOrder.pm for valid switches
# switch may or may not be associated with a sub
# format: switch = > anonomous array ref
#         switch => [\&sub, 1/0 takes/does not take a parameter]
#         switch => [0, 0/1 (not)/takes a parameter]
# -a -d take parameters, -b -c do not, -e is not associated with a sub
my %subhash = ( -a => [\&another, 1],
                -b => [\&brady, 0],
                -c => [\&cleo, 0],
                -d => [\&dumbfries, 1],
                -e => [0, 0]);

# construct the object
my $control = cmdlOrder->new(\%subhash);

print @ARGV . "\n";
.cmdlOrder->execsub(\@ARGV);
