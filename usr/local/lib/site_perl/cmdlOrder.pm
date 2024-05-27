package cmdlOrder;

# this is class that makes the order of execution
# of subs the same as the order given on the commandline.
# a switch -a will invoke a sub which is registered in the hash
# if the parameter following -a on command line is not another switch
# it is taken to be a parameter and passed to the sub for a.
# If there is no parameter for sub a, nothing is passed.
# the subs themselves must be able to accept a variable no of arguments

# the constructor needs a ref to a hash
# which contains switch => reference to sub
# eg $refhash = { -a => \&suba, -c => \&subc, ....}
# this hash ref must be passed to the contructor new(\%hashofsubs)


use strict;
use warnings;

# ref to hash containing switch => ref to sub to invoke
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

	# invoke subs from cmdl switches
	for (my $i=0; $i<scalar(@$refsw); $i++) {
		# get sub ref if parameter is a switch
		# if it is not a switch, it must be
		# a parameter to the previous switch
		if ($refsw->[$i] =~ /^-/) {
			# check if the switch (key) exists in the hash
			# print and error message if not
			if (exists($refhash->{$refsw->[$i]})) {
				$refsub = $refhash->{$refsw->[$i]};
				# if next cmdl option is not
				# a switch, it must be a parameter
				# do not go past the end of the list
				if ($i < scalar(@$refsw)) {
					if ($i < scalar(@$refsw) - 1 and $refsw->[$i+1] !~ /^-/) {
						# this is the parameter for the previous switch
						# invoke sub
						print "calling $refsub with parameter $refsw->[$i+1]\n";
						$refsub->($refsw->[$i+1]);

						# increase i
						$i++;
					} else {
						# there is no parameter
						# for this switch
						# this could also be the last switch
						# invoke the sub
						print "last switch $refsw->[$i]\n" if $i == scalar(@$refsw) - 1;
						$refsub->();
					}
				}
			} else {
				# print message show not a valid switch
				print "Invalid switch: $refsw->[$i]\n";
			}
		}
	}
	return;
}
1;
