package cmdlOrder;

# this is class that makes the order of execution
# of subs the same as the order given on the commandline.
# a switch -a will invoke a sub which is registered in the hash
# if the parameter following -a on command line is not another switch
# it is taken to be a parameter and passed to the sub for a.
# If there is no parameter for sub a, nothing is passed.
# the subs themselves must be able to accept a variable no of arguments
# a switch that is not associated with a sub has a global var $opt_switch
# associated with it. this is set to 1 if the switch is given.




use strict;
use warnings;

# ref to hash = (switch => [reftosub, \$opt_switch]
#                switch => [0, \$opt_switch],  if there is no associated sub
#
my $refhash;

# ref to array containing command line switches
my $refswlist;

#######################################################
# constructor registers hash reference
# and command line parameters and 
# sets all global vars $opt_switch associated
# with switches but not with subs.
# this is done as some switches must be
# set before any methods are executed.
# parameters: ref to hash of switches and subs
#             ref to array of command line parameters
#######################################################
sub new {
	print "invoking cmdlOrder->new()\n";
	# get parameters
	# there must be 2 parameters
	die "ref to hash with switches/subs and ref to command line array required\n" unless scalar(@_) >= 3;
	my $class = shift @_;

	# get ref to hash
	$refhash = shift @_;
	
	# get ref to command line array of switches
	$refswlist = shift @_;
	
	# set all switches to their values unless they are associated with a sub
	# if a switch has a parameter, $opt_switch = parameter value
	# else $opt_switch = "null" to indicate no parameter
	# and it is on the command line
	# for all items in cmd line list
	for (my $i=0; $i<scalar(@$refswlist); $i++) {
		# check that it is a switch
		my $switch = $refswlist->[$i];
		
		if ($switch=~ /^-/) {
			# this is a switch
			# check if it is valid
			if (exists($refhash->{$switch})) {
				# switch is valid
				# check if a sub is associated
				if ($refhash->{$switch}->[0] == 0) {
					# valid switch not associated with sub
					# the switch must be set to parameter value
					# or null if there is no parameter
					# don't move past end of list
					if ($i < scalar(@$refswlist) - 1 and $refswlist->[$i+1] !~ /^-/) {
						# valid switch with a parameter
						# set the value
						${$refhash->{$switch}->[1]} = $refswlist->[$i+1];
						print "$switch: ${$refhash->{$switch}->[1]}\n";
						
						# switch might be the last on the line
					} elsif ($i < scalar(@$refswlist) and $refswlist->[$i] =~ /^-/) {
						# this is a switch with no parameter
						${$refhash->{$switch}->[1]} = "null";
						print "$switch: ${$refhash->{$switch}->[1]}\n";
					} else {
						# code should never get here
						print "line 80: Error: switch: $switch\ni: $i\n";
					}
				}
			} else {
				# switch does not exist
				print "$refswlist->[$i] is invalid\n";
			}
		}
	}

	# make class into an object
	my $self = {};
	bless $self, $class;
	return $self;	
}	 

# method to invoke subs with parameters
# following command line order
# parameters : none
# return: nothing
######################################################
sub execsub {
	# get parameters
	my $self = shift @_;

	# general ref to subs
	# to be invoked
	my $refsub;

	# a list of sub refereces to invoke.
	# @execsublist = (reftosub, switch, parameter or "null")
	my @execsublist = ();
	
	# invoke subs from cmdl switches
	for (my $i=0; $i<scalar(@$refswlist); $i++) {
		# get sub ref if parameter is a switch
		# if it is not a switch, it must be
		# a parameter to the previous switch
		if ($refswlist->[$i] =~ /^-/) {
			# check if the switch (key) exists in the hash
			# print and error message if not
			# refhash is ref to hash $refhash = {switch => [reftosub/0, global var $opt_switch = 1/parameter]}
			# variable for switch
			my $switch = $refswlist->[$i];
			
			if (exists($refhash->{$switch})) {
				$refsub = $refhash->{$switch}->[0];
				# does refsub point to a sub?
				# if ref is either a sub ref
				# or a 0 meaning no sub is referenced.

				# refsub points to a sub or 0
				# determine if there is a 
				# parameter following and execute the sub
				# set global $opt_switch = parameter
				# push the ref to a list
				# so that all invokations take
				# place after the cmd line parameters
				# have been parsed. This ensures
				# all global vars are set before invokation.
				# if next cmdl option is not
				# a switch, it must be a parameter
				# do not go past the end of the list
				if ($i < scalar(@$refswlist)) {
					# check if next item is a switch or parameter
					if ($i < scalar(@$refswlist) - 1 and $refswlist->[$i+1] !~ /^-/) {
						# this is the parameter for the previous switch
						
						
						# add sub ref to list for invokation
						# unless the reference is 0
						if ($refsub != 0) {
							print "switch = $switch: refsub = $refsub: parameter = $refswlist->[$i+1]\n";
							push @execsublist, $refsub;
						
							# push the switch to the next value
							push @execsublist, $switch;

							# add to list to exectute all subs
							# push the parameter
							push @execsublist, $refswlist->[$i+1];
                        } else {
							# ref to sub is 0
							# with parameter
							print "switch = $switch: refsub = $refsub: parameter = $refswlist->[$i+1]\n";
						}

						# set associated ref to $opt_switch in hash to the value
						# of the parameter
						${$refhash->{$switch}->[1]} = $refswlist->[$i+1];

						# increase i
						$i++;
					} else {
						# there is no parameter
						# this could also be the last switch
						# the switch is still $refswlist->[$i]

						# add to execsublist only if ref != 0
						if ($refsub != 0) {
							print "switch = $switch: refsub = $refsub: no parameter\n";
							# add to list execute all subs
							push @execsublist, $refsub;

							# push the switch to the next value
							push @execsublist, $switch;

							# push null to indicate no value
							push @execsublist, "null";
						} else {
							# ref to sub is 0
							# with no parameter
							print "switch = $switch: refsub = $refsub:  no parameter\n";
						}

						# to indicate switch is there but
						# no parameter is associated
						${$refhash->{$switch}->[1]} = "null";
					}
				}
			} else {
				# print message show not a valid switch
				print "Invalid switch: $refswlist->[$i]\n";
			}
					
		}
	}
	# now all global vars have been set
	# invoke the subs in the order of execsublist
	print "execsublist = @execsublist\n";
	
	# @execsublist = (reftosub 1, switch, parameter ......)
	for (my $i=0; $i<scalar(@execsublist); $i=$i+3) {
		# invoke sub , parameter is in $opt_switch
		# set global var $opt_switch for
		# this call. get the switch
		my $switch = $execsublist[$i+1];
		
		# set the global var for this call
		${$refhash->{$switch}->[1]} = $execsublist[$i+2];

		# if there is one, otherwise null.
		$execsublist[$i]->();
	}
	return;
}
1;
