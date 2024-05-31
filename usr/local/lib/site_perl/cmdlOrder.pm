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

#######################################################
# constructor setups up hash reference
#######################################################
sub new {
	# get parameters
	# there must be 2 parameters
	die "A reference to a hash containing switch => ref to sub must be provided\n" unless scalar(@_) >= 2;
	my $class = shift @_;

	# get ref to hash
	$refhash = shift @_;
	
	
	# make class into an object
	my $self = {};
	bless $self, $class;
	return $self;	
}	 

######################################################
# method to invoke subs with parameters
# following command line order
# parameters : string for cmdl switches with parameters
# return: nothing
######################################################
sub execsub {
	# check no of parameters passed
	die "The cmdl string with switches and parameters must be passed to this method\n" if scalar(@_) < 2;

	# get parameters
	my $self = shift @_;

	# ref to cmdl array of switches
	my $refsw = shift @_;
	# general ref to subs
	# to be invoked
	my $refsub;

	# a list of sub refereces to invoke.
	# @execsublist = (reftosub, switch, parameter or "null")
	my @execsublist = ();
	
	# invoke subs from cmdl switches
	for (my $i=0; $i<scalar(@$refsw); $i++) {
		# get sub ref if parameter is a switch
		# if it is not a switch, it must be
		# a parameter to the previous switch
		if ($refsw->[$i] =~ /^-/) {
			# check if the switch (key) exists in the hash
			# print and error message if not
			# refhash is ref to hash $refhash = {switch => [reftosub/0, global var $opt_switch = 1/parameter]}
			# variable for switch
			my $switch = $refsw->[$i];
			
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
				if ($i < scalar(@$refsw)) {
					# check if next item is a switch or parameter
					if ($i < scalar(@$refsw) - 1 and $refsw->[$i+1] !~ /^-/) {
						# this is the parameter for the previous switch
						
						
						# add sub ref to list for invokation
						# unless the reference is 0
						if ($refsub != 0) {
							print "switch = $switch: refsub = $refsub: parameter = $refsw->[$i+1]\n";
							push @execsublist, $refsub;
						
							# push the switch to the next value
							push @execsublist, $switch;

							# add to list to exectute all subs
							# push the parameter
							push @execsublist, $refsw->[$i+1];
                        } else {
							# ref to sub is 0
							# with parameter
							print "switch = $switch: refsub = $refsub: parameter = $refsw->[$i+1]\n";
						}

						# set associated ref to $opt_switch in hash to the value
						# of the parameter
						${$refhash->{$switch}->[1]} = $refsw->[$i+1];

						# increase i
						$i++;
					} else {
						# there is no parameter
						# this could also be the last switch
						# the switch is still $refsw->[$i]

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
				print "Invalid switch: $refsw->[$i]\n";
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
