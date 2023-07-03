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
# parameter: optional address
sub delete {
	my $self = shift;
	my $addr = shift;

	# delete all lines that match address
	# if address is "" then delete all lines
	# copy non matching lines to new array
	# set efile = to new array
	# return no of lines deleted
	my @temparray = ();
	my $count = 0;
	foreach my $line (@efile) {
		if ($line =~ /$addr/) {
			# delete line and count it
			$count++;
		} else {
			# keep line
			push @temparray, $line;
		}
	}
	# set efile to new array
	@efile = @temparray;
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
