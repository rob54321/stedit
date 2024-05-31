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

our ($opt_a, $opt_b, $opt_c, $opt_d, $opt_e, $opt_A);

sub another {
	print "sub a $opt_a\n";
	if ($opt_A) {
		print "opt_A is defined = $opt_A\n";
	} else {
		print "opt_A not defined\n";
	}
}

sub brady {
	print "sub b $opt_b\n";
	print "sub b opt_A: $opt_A\n" if $opt_A;
	print "sub b opt_e: $opt_e\n" if $opt_e;
}

sub cleo {
	print "sub c $opt_c\n";
}

sub dumbfries {
	my $pm = $opt_d;
	print "sub d with parameter $pm\n";
}

# hash for cmdlOrder.pm for valid switches
# switch may or may not be associated with a sub
# format: 
#         switch => [reftosub, \$opt_switch]
#	  switch => [0, \$opt_switch], if there is no associated sub.
#         $opt_switch = parameter value | null in case where there is no ref to sub
# $opt_switch is declared as our ($opt_switch)
my %subhash = ( -a => [\&another, \$opt_a],
                -b => [\&brady, \$opt_b],
                -c => [\&cleo, \$opt_c],
                -d => [\&dumbfries, \$opt_d],
                -e => [0, \$opt_e],
		-A => [0, \$opt_A]);

# construct the object
my $control = cmdlOrder->new(\%subhash);

print @ARGV . "\n";
cmdlOrder->execsub(\@ARGV);
