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
# return: no of lines deleted
#         -1 on error
sub delete {
	# for debug
	my @debug = ("***Delete***\n") if $DEBUG;
	
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

	# get parameters
	$_ = $count;
	SWITCH: {
		/^2/ && do {$pattern = shift; $modi = ""; last SWITCH;};
		/^3/ && do {$pattern = shift; $modi = shift; $modi = "" unless $modi eq "i"; last SWITCH;};
		print "delete error: $count parameters passed\n"; return -1;
	}
	# debug print parameters
	# delete all lines that match address
	# if address is "" then delete all lines
	# copy non matching lines to new array
	# set efile = to new array
	# return no of lines deleted
	my @temparray = ();

	# reset count for no of lines deleted.
	$count = 0;

	# for debug
	push @debug, "pattern = $pattern ; modifier = $modi\n" if $DEBUG;
	
	# if modifier is i
	if ($modi eq "i") {
		foreach my $line (@efile) {
			# case insensitive pattern
			if ($line =~ /$pattern/i) {
				# DEBUG: print the line
				push @debug, "deleted: $line\n" if $DEBUG;
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
				# DEBUG: print the line
				push @debug, "deleted: $line\n" if $DEBUG;
				# delete line and count it
				$count++;
			} else {
				# keep line
				push @temparray, $line;
			}
		}
	}
	
	# for debug
	push @debug, "$count lines deleted\n" if $DEBUG;
	
	# set efile to new array
	@efile = @temparray;
	# for debug
	$self->display(\@debug) if $DEBUG;

	return $count;
}

# sub to subsitute in each line of the file
# parameters: 1. pattern
#             2. replacement
#             3, modifier i or g or ig or gi - optional
# if no modifier given or a bad one, set $modi = "" = no modifier
# return: no of subsitutions
#         -1 on error
sub subst {
	# for debug
	my @debug = ("***Subst***\n") if $DEBUG;
	
	# no of parameters passed
	my $count = scalar (@_);

	# there must be 4 or 3 parameters passed
	my $self = shift;
	my $patt;
	my $repl;
	my $modi;
	$_ = $count;
	
	# get parameters
	SWITCH: {
		/^3/ && do {$patt = shift; $repl = shift; $modi = ""; last SWITCH;};
		/^4/ && do {$patt = shift; $repl = shift; $modi = shift; $modi = "" unless $modi =~ /^i$|^g$|^ig$|^gi$/; last SWITCH;};
		print "susbst error: $count parameters passed\n"; return -1;
	}

	# for debug
	push @debug, "pattern = $patt : replacement = $repl : modifier = $modi\n" if $DEBUG;
	
	# the modifier can be
	# i - case insensitive
	# g - global search in line
	# not just first occurence
	# search each line
	$count = 0;
	my $noofmatches;
	# substitutions depend on the modifier
	# "" means no modifier

	# for debugging
	my $oldline if $DEBUG;
	if ($modi eq "g") {
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$patt/$repl/g;
			#for debug
			push @debug, "old: $oldline\nnew: $line\n" if $DEBUG and ($noofmatches > 0);
			
			# add up matches
			$count = $count + $noofmatches;
		}
	} elsif ($modi eq "i") {
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$patt/$repl/i;
			#for debug
			push @debug, "old: $oldline\nnew: $line\n" if $DEBUG and ($noofmatches > 0);
			
			$count = $count + $noofmatches;
		}
	} elsif ($modi =~ /i/ and $modi =~ /g/) {
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$patt/$repl/ig;
			#for debug
			push @debug, "old: $oldline\nnew: $line\n" if $DEBUG and ($noofmatches > 0);
			
			$count = $count + $noofmatches;
		}

	} else {
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$patt/$repl/;
			#for debug
			push @debug, "old: $oldline\nnew: $line\n" if $DEBUG and ($noofmatches > 0);
			
			$count = $count + $noofmatches;
		}
	}

	# for debug
	push @debug, "$count substitutions\n" if $DEBUG;
	
	# for debug
	$self->display(\@debug) if $DEBUG;
	
	# return no of matches
	return $count;
}

# method to append a string to the end of a file
# parameters: 1 the string to be appended
# return: 1 on success
#         -1 on error
sub append {
	# for debug
	my @debug = ("***Append***\n") if $DEBUG;
	
	#get parameters
	my $count = scalar(@_);

	# for debug
	push @debug, "no of parameters = $count\n" if $DEBUG;
	
	if ($count != 2) {
		print "append error: $count parameters passed \n";
		return -1;
	}
	my $self = shift;
	my $text = shift;

	# append the string to the efile array
	# string can be : something\nnew line\n\tnew line again\n\tetc
	push @efile, $text;
	# for debug
	$self->display(\@debug) if $DEBUG;
	
	return 1;
}

# method to insert a string(s) in a file
# after or before a certain line.
# the pattern can have modifiers, i case insensitive
#                                 b before match
#                                 a after match
# parameters
#   1. pattern to match
#   2. text to be inserted
#   3. modifiers 
#      i for case insensitive
#      b before match
#      a after match
# return: -1 on error
#          1  on success
#          0  on match not found
sub insert {
	# for debug
	my @debug = ("***Insert***\n") if $DEBUG;
	
	# get parameters
	my $count = scalar(@_);
	my $self = shift;
	my $pattern;
	my $text;
	my $modi;
	
	# set the vars depending on how many parameters were passed
	$_ = $count;
	SWITCH: {
		/^3/ && do { $pattern = shift; $text = shift; $modi = ""; last SWITCH};
		/^4/ && do { $pattern = shift; $text = shift; $modi = "" unless $modi =~ /i|b|a|ib|ia|/; last SWITCH};
		print "insert error: $count parameters supplied\n"; return -1;
	}

	push @debug, "count = $count: pattern = $pattern: modi = $modi\n" if $DEBUG;

	# insert text before/after case (in) sensitive to each matching line.
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
# mainly for debugging.
# parameters: optional title
# return: nothing
sub display {
	my $count = scalar(@_);
	my $self = shift;

	# if title given print it
	# a title is a reference to list lines
	do {my $title = shift; print "###################\n@{$title}\n#################\n";} if $count == 2;
	foreach my $line (@efile) {
		print "$line\n";
	}
}
# this is the last line of the module and must be here
1;
