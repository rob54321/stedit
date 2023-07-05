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
use File::Copy;

# DEBUG FLAG, true for debugging or else false
my $DEBUG = 1;

# file name
my $fname;

# array to hold file line by line.
my @efile = ();

# constructor.
# the file is copied to filename.bak
# filename.bak is overwritten if it exists.
# parameter is the name of the file to edit
# the file is read line by line into an array, 
# a class variable.
# die if the file cannot be opened for reading

sub new {
	my $class = shift;
	# get file name
	$fname = shift;
	
	# make a backup copy to fname.bak
	copy($fname, $fname . ".bak") or die "Could not copy $fname to $fname.bak : $!\n" unless -f $fname . ".bak";

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
# parameter: address pattern to match,optional modifier i
# if not i then it is "" = no modifier
# if no pattern address is given, return -1
# return no of lines deleted
sub delete {
	# get the no of parameters passed
	my $count = scalar (@_);
	
	my $self = shift;

	# there must be 2 or 3 parameters
	# if there is no address pattern - return error
	# get parameters
	# 2 parameters means pattern address but no pattern modifier
	# 3 parameters means pattern address and pattern modifier
	my $pattern;
	my $modi;
	if ($count == 2) {
		$pattern = shift;
		# no modifier
		$modi = "";
	} elsif ($count == 3) {
		$pattern = shift;
		$modi = shift;

		# if the modifier is not i
		# i is for case insensitive
		# set to "" - no modifier
		$modi = "" unless $modi eq "i";
	} else {
		# incorrect no parameters
		print "Error : $count parameters passed\n";
		return -1;
	}
	# debug print parameters
	print "pattern = $pattern ; modifier = $modi\n" if $DEBUG;
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
		print "delete: modifier i\n" if $DEBUG;
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
		print "delete: modifier none \n" if $DEBUG;
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
# parameters: pattern, replacement, optional modifier i or g or ig or gi
# if no modifier given or a bad one, set $modi = "" = no modifier
# returns no of subsitutions
sub subst {
	# no of parameters passed
	my $count = scalar (@_);

	# there must be 4 or 3 parameters passed
	my $self = shift;
	my $patt;
	my $repl;
	my $modi;
	if ($count == 4) {
		# get parameters
		$patt = shift;
		$repl = shift;
		# $modi is defined, check it's validity
		$modi = shift;
		# set it to "" if it does not contain i or g or both.
		# empty is also disqualified

		$modi = "" if $modi !~ /^i$|^g$|^ig$|^gi$/;
	} elsif ($count == 3) {
		# get parameters
		$patt = shift;
		$repl = shift;
		# no modifier passed
		$modi = "";
	} else {
		# incorrect no of parameters passed
		print "Error : $count parameters passed\n";
		return -1;
	}

	# the modifier can be
	# i - case insensitive
	# g - global search in line
	# not just first occurence
	# search each line
	$count = 0;
	my $noofmatches;
	# substitutions depend on the modifier
	# "" means no modifier
	if ($modi eq "g") {
		print "subst modifier g\n" if $DEBUG;
		foreach my $line (@efile) {
			$noofmatches = $line =~ s/$patt/$repl/g;
			# add up matches
			$count = $count + $noofmatches;
		}
	} elsif ($modi eq "i") {
		print "subst modifier i\n" if $DEBUG;
		foreach my $line (@efile) {
			$noofmatches = $line =~ s/$patt/$repl/i;
			$count = $count + $noofmatches;
		}
	} elsif ($modi =~ /i/ and $modi =~ /g/) {
		print "subst modifier ig\n"if $DEBUG;
		foreach my $line (@efile) {
			$noofmatches = $line =~ s/$patt/$repl/ig;
			$count = $count + $noofmatches;
		}

	} else {
		print "subst modifier none\n" if $DEBUG;
		foreach my $line (@efile) {
			$noofmatches = $line =~ s/$patt/$repl/;
			$count = $count + $noofmatches;
		}
	}

	# return no of matches
	return $count;
}

# method to write file to disk
sub write {
	# get parameters
	my $self = shift;

	# write the efile to disk
	open (my $fh, ">", $fname) or die "Could not open $fname for writing: $!\n";

	foreach my $line (@efile) {
		print $fh "$line\n";
	}

	# close file
	close $fh;
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
