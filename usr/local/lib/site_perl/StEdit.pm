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
my $DEBUG = 0;

# file name
my $fname;

# array to hold file line by line.
my @efile = ();

# constructor.
# the file is copied to filename.bak
# filename.bak is overwritten if it exists.
# parameters: 1. file name to be edited
#             2. optional DEBUG FLAG 1 - debugging on, 0 - debugging off
# the file is read line by line into an array, 
# a class variable.
# die if the file cannot be opened for reading

sub new {
	# get no of parameters
	my $count = scalar(@_);
	my $class = shift;
	# if no file name passed - die
	die "A full path name must be specified\n" if $count < 2;
	
	# get file name
	$fname = shift;
	# get DEBUG flag if it is passed
	$DEBUG = shift if $count == 3;;
	
	#open file for reading
	open (my $fh, "<", $fname) or die "new: Could not open $fname: $!\n";
	# read all lines
	while (my $line = <$fh>) {
		# remove terminator at end
		chomp($line);
		# add to array
		push (@efile, $line);
	}

	# close file
	close $fh;
		
	# make a backup copy to fname.bak
	copy($fname, $fname . ".bak") or die "new: Could not copy $fname to $fname.bak : $!\n" unless -f $fname . ".bak";

	my $self = {};
	bless $self, $class;
	return $self;
}

# delete function
# delete each line matching the pattern
# if no pattern is given return an error
# addr is of form:
#   "^string"
#   "string\$"
#   "string"
#   "st\.\*ng"
#   "\\bstring\$"
# parameter: address pattern to match,optional modifier i
# if not i then it is "" = no modifier
# return: no of lines deleted
#         undefined on error
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
		/^3/ && do {$pattern = shift; $modi = shift; unless ($modi eq "i" or $modi eq "") {
							             print "delete: Invalid modifier $modi\n";
								     return;} last SWITCH;};
		print "delete error: $count parameters passed\n"; return;
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
	if ($DEBUG) {
		foreach my $item (@debug) {
			print "$item";
		}
		print "###########\n";
	}

	return $count;
}

# sub to subsitute in each line of the file
# parameters: 1. pattern
#             2. replacement
#             3, modifier i or g or ig or gi - optional
# if no modifier given or a bad one, set $modi = "" = no modifier
# return: no of subsitutions
#         undefined on error
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
		/^4/ && do {$patt = shift; $repl = shift; $modi = shift; unless ($modi =~ /^i$|^g$|^ig$|^gi$/ or $modi eq "") {
										# invalid modifier
										print "subst: Invalid modifier $modi\n";
										return;} last SWITCH;};
		print "susbst error: $count parameters passed\n"; return;
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
	if ($DEBUG) {
		foreach my $item (@debug) {
			print "$item";
		}
		print "###########\n";
	}

	# return no of matches
	return $count;
}

# method to append a string to the end of a file
# parameters: 1 the string to be appended
# return: 1 on success
#         undefined on error
sub append {
	# for debug
	my @debug = ("***Append***\n") if $DEBUG;
	
	#get parameters
	my $count = scalar(@_);

	# for debug
	push @debug, "no of parameters = $count\n" if $DEBUG;
	
	if ($count != 2) {
		print "append error: $count parameters passed \n";
		return;
	}
	my $self = shift;
	my $text = shift;

	# append the string to the efile array
	# string can be : something\nnew line\n\tnew line again\n\tetc
	push @efile, $text;
	# for debug
	# for debug
	if ($DEBUG) {
		foreach my $item (@debug) {
			print "$item";
		}
		print "###########\n";
	}

	
	return 1;
}

# sub to insert a line after/before a line
# parameters: 1. ref to line
#             2. ref to text
#             3. ref to temparray
#             4. modifier a or b
# return: nothing
sub insertline {
	# get parameters
	my $self = shift;
	my $rline = shift;
	my $rtext = shift;
	my $rtemparray = shift;
	my $modi = shift;

	# for debugging
	my $dline if $DEBUG;
	
	# insert
	if ($modi =~ /a/) {
		# insert text after a line
		push @{$rtemparray}, ${$rline};
		push @{$rtemparray}, ${$rtext};
		# for debug
		$dline = "old: ${$rline}\nnew: ${$rtext}\n" if $DEBUG;
	} else {
		# insert before a line - default
		push @{$rtemparray}, ${$rtext};
		push @{$rtemparray}, ${$rline};
		# for debug
		$dline = "new: ${$rtext}\nold: ${$rline}\n" if $DEBUG;
	}

	# for debugging
	print "$dline" if $DEBUG;
	return;
}
# method to insert a string(s) in a file
# after or before a certain line.
# the default is insert before a line
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
# return: undefined on error
#          count  on success
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
	my @temparray = ();
	
	# set the vars depending on how many parameters were passed
	# the modifier can be i a b. any combination of ab is invalid
	# and returned on error.
	$_ = $count;
	SWITCH: {
		/^3/ && do { $pattern = shift; $text = shift; $modi = ""; last SWITCH;};

		/^4/ && do { $pattern = shift; $text = shift; $modi = shift;
				# if modi does not contain a valid modifier
				unless ($modi =~ /^i$|^b$|^a$|^ib$|^bi$|^ia$|^ai$/ or $modi eq "") {
					print "insert: Invalid modifier $modi\n";
					return;} last SWITCH;};
		print "insert error: $count parameters supplied\n"; return;
	}

	push @debug, "count = $count: pattern = $pattern: modi = $modi\n" if $DEBUG;

	# insert text before/after case (in) sensitive to each matching line.
	# for all elements in list
	# no of insertions
	$count = 0;
	foreach my $line (@efile) {
		# copy each line that does not match to temparray
		# when line matches insert before/after line in temparray
		if ($modi =~ /i/) {
			# check for match
			if ($line !~ /$pattern/i) {
				# no match , copy line
				push @temparray, $line;
			} else {
				# line does match.
				# insert text before or after
				$self->insertline(\$line, \$text, \@temparray, $modi);

				# count insertions
				$count++;
			}
		} else {
			# no i modifier
			# check for match
			if ($line !~ /$pattern/) {
				# no match , copy line
				push @temparray, $line;
			} else {
				# line does match.
				# insert text before or after
				$self->insertline(\$line, \$text, \@temparray, $modi);

				# count insertions
				$count++;
			}
		}
	}
	# copy temp array to efile
	@efile = @temparray;

	# for debug
	push @debug, "$count times inserted\n" if $DEBUG;
	# for debug
	if ($DEBUG) {
		foreach my $item (@debug) {
			print "$item";
		}
		print "###########\n";
	}

	return $count;
}
	
# method to write file to disk
# parameters: optional file name will be written to if given
# return: nothing
sub write {
	my $count = scalar(@_);
	
	# get parameters
	my $self = shift;

	# if 2 parameters were passed
	# if file name was "" then
	# use original name $fname
	my $filewrite = $fname;

	# for stedit.pl if -w has no argument "" is used
	# as a default parameter. -w must have a parameter
	# for getopts to work
	$filewrite = shift if $count == 2 and $_[0] ne "";
	print "filename: $filewrite\n" if $DEBUG;

	# write the efile to disk
	open (my $fh, ">", $filewrite) or die "Could not open $fname for writing: $!\n";

	foreach my $line (@efile) {
		print $fh "$line\n";
	}

	# close file
	close $fh;
}
	
# display the buffer for testing purposes
# mainly for debugging.
# return: nothing
sub display {
	my $self = shift;

	# print each line
	foreach my $line (@efile) {
		print "$line\n";
	}
}
# this is the last line of the module and must be here
1;
