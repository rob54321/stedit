package StEdit;

# A stream line edit written in perl
# each method implements a different
# editing command. substitute, delete, append, insert etc.
# each command takes an address, then 0 or 1 or 2 parameters
# depending on the command.
# The optional address:
# - a string which will be matched at each line
# - no address then every line
# - optional control characters
# -- ^ indicates begining of line
# -- $ end of line or end of file
use strict;
use warnings;

# file name
my $fname;

# array to hold file line by line.
my @efile = ();

# constructor.
# parameter is the name of the file to edit
# the file is read line by line into an array, 
# a class variable.
# die if the file cannot be opened for reading

sub new {
	my $class = shift;
	# get file name
	$fname = shift;
	
	#open file for reading
	open (my $fh, "<", $fname) or die "Could not open $fname: $!\n";
	# read all lines
	while (my $line = <$fh>) {
		# remove terminator at end
		chomp($line);
		# add to array
		push (@efile, $line);
	}

	# close file
	close $fh;
		
	my $self = {};
	bless $self, $class;
	return $self;
}

# delete function
# delete each line matching the address
# or if no address, delete all lines
# addr is of form:
#   "^string"
#   "string\$"
#   "string"
#   "st\.\*ng"
#   "\\bstring\$"
# parameter: address pattern to match,optional modifier i - case insensitive match
# return no of lines deleted
sub delete {
	# get the no of parameters passed
	my $count = scalar (@_);
	
	my $self = shift;

	# there must be 2 or 3 parameters
	# if there is no address pattern - return error
	return undef if $count < 2;

	# get parameters
	# 2 parameters means pattern address but no pattern modifier
	# 3 parameters means pattern address and pattern modifier
	my $pattern;
	my $modi;
	if ($count == 2) {
		$pattern = shift;
		$modi = undef;
	} elsif ($count == 3) {
		$modi = shift;

		# if the modifier is not i
		# i is for case insensitive
		# set to undef
		$modi = undef unless $modi eq "i";
	}

	# delete all lines that match address
	# if address is "" then delete all lines
	# copy non matching lines to new array
	# set efile = to new array
	# return no of lines deleted
	my @temparray = ();

	# reset count for no of lines deleted.
	$count = 0;

	# if modifier is i
	if ($modi eq "i") {
		foreach my $line (@efile) {
			# case insensitive pattern
			if ($line =~ /$pattern/i) {
				# delete line and count it
				$count++;
			} else {
				# keep line
				push @temparray, $line;
			}
		}
	} else {
		foreach my $line (@efile) {
			# case sensitive search
			if ($line =~ /$pattern/) {
				# delete line and count it
				$count++;
			} else {
				# keep line
				push @temparray, $line;
			}
		}
	}
	
	# set efile to new array
	@efile = @temparray;
	return $count;
}

# sub to subsitute in each line of the file
# parameters: pattern, replacement, modifier
# returns no of subsitutions
sub subst {
	my $self = shift;
	my $patt = shift;
	my $repl = shift;

	# modi may have values: undefined, defined with no value, or have a value

	my $modi;
	if ($#_ == 0) {
		# $modi is defined but may or may not have a value
		$modi = shift;
		# undefine it if it does not contain i or g or both.
		# empty is also disqualified
		undef $modi if $modi !~ /^i$|^g$|^ig$|^gi$/;
	}

	# the modifier can be
	# i - case insensitive
	# g - global search in line
	# not just first occurence
	# search each line
	my $count = 0;
	my $noofmatches;
	# $modi may or may not be defined
	if (defined($modi)) {
		if ($modi eq "g") {
print "got g\n";
			foreach my $line (@efile) {
				$noofmatches = $line =~ s/$patt/$repl/g;
				# add up matches
				$count = $count + $noofmatches;
			}
		} elsif ($modi eq "i") {
print "got i\n";
			foreach my $line (@efile) {
				$noofmatches = $line =~ s/$patt/$repl/i;
				$count = $count + $noofmatches;
			}
		} elsif ($modi =~ /i/ and $modi =~ /g/) {
print "got ig\n";
			foreach my $line (@efile) {
				$noofmatches = $line =~ s/$patt/$repl/ig;
				$count = $count + $noofmatches;
			}

		}
	} else {
print "no modifier\n";
		foreach my $line (@efile) {
			$noofmatches = $line =~ s/$patt/$repl/;
			$count = $count + $noofmatches;
			}
	}

	# return no of matches
	return $count;
}
# display the buffer for testing purposes
sub display {
	my $self = shift;
	
	foreach my $line (@efile) {
		print "$line\n";
	}
}
# this is the last line of the module and must be here
1;
