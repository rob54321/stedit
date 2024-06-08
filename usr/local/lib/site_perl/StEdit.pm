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
		
	my $self = {};
	bless $self, $class;
	return $self;
}


####################################################
# parsearg function:
# argument is of form:
# subs:     /pattern/resplacement/ig
# delete:   /pattern/i
# insert:   /pattern/text/iab
# append:   text
# strip off the / / 
# parameters passed: 1. command name, s, d, i, a
#                    2. argument string
#                    3. ref to array for returning pattern, replacement, option1,...etc
#                    
# return:  for subs:      return ref to [pattern, replacement, options|none]
#              delete:    return ref to [pattern, option|none ]
#              insert:    return ref to [pattern, text, options|nothing]]
#              append:    return ref to [text]
#              options:   a variable length string like i or ig or ia or ib or a or b or nothing
###################################################
sub parsearg {
	# Get parameters
	my $self = shift @_;
	my $cmd = shift @_;
	my $arg = shift @_;
	my $reflist = shift @_;
	
	# arg can only be of form
	# /pattern/i or
	# /pattern/text/abi
	# /pattern/replacement/ig
	# split the arg
	# note: the arg for append and delete may not have the leading and trailing slash
	# the subs and insert commands must have three slashes /pattern/text/options
	
	# list to store components of the argument
	my @list;
	
	if ($cmd eq "a" || $cmd eq "d") {
		# append and delete may or may not have slashes
		# around argument
		# if there are no slashes, there can be no options
		# make sure there are no groups of 2 or more / together
		if ($arg =~ /^\/.*\// and $arg !~ /\/{2,}/) {
			# arg of form /pattern/
			@list = split /\//,$arg;
			# remove first empty element
			shift @list;
		}
	} elsif ($cmd eq "i" || $cmd eq "s") {
		# subs and insert have arg /pattern/text/options or none
		# retrieve the arguments
		if ($arg =~ /^\/.*\/.*\// and $arg !~ /\/{2,}/) {
			@list = split /\//, $arg;
			# remove first empty element
			shift @list;
		}
	}

	# print all arguments form @list
	do {
		print "################StEdit->parsearg()######################\n";
		print "command $cmd: no of \@list args ". scalar(@list) . "\n";
		for (my $i=0; $i<scalar(@list); $i++) {
			print "list[$i]: $list[$i]\n" if $list[$i];
		}
		print "################################################\n\n";
	} if $DEBUG;
	
	# check that the arg is not mal formed
	die "StEdit->parsarg(): The arg = $arg for command $cmd is malformed\n" if scalar(@list) == 0 or ! defined($list[0]);

	# for each command
	if ($cmd eq "d") {
		# for delete command: arg is /pattern/i or /pattern/
		$reflist->[0] = $list[0];
		# copy options if there are any
		$reflist->[1] = $list[1] if $list[1];
	} elsif ($cmd eq "a") {
		# for append command: arg is text
		$reflist->[0] = $list[0];
	} elsif ($cmd eq "i" or $cmd eq "s") {
		# check that format of arg is /pattern/text/options|none
		# die if there are 2 or more / together or if there are no /
		die "the format of arg $arg is wrong should be \/pattern\/text\/options|none\n" if ($arg !~ /^\/.*\/.*\// or $arg =~ /\/{2,}/);
		
		# for insert or subs command: /pattern/text/ or /pattern/text/i|a|b|g or none
		$reflist->[0] = $list[0];
		$reflist->[1] = $list[1];
		# if there are options
		$reflist->[2] = $list[2] if $list[2];
	}
}

####################################################################
# delete function
# delete each line matching the pattern
# parameter: of form /pattern/ie or /pattern/
# the modifiers are optional
# i - for case insensitive
# e - delete line and following lines if they are empty
# return: no of lines deleted
#         undefined on error
###################################################################
sub delete {
	# for debug
	my @debug = ("################# StEdit->delete() ####################\n") if $DEBUG;
	
	my $self = shift;

	# cmd line argument like /pattern/ or pattern/i
	my $arg = shift @_;
	
	# parse the arg
	my @list;
	$self->parsearg("d", $arg, \@list);
	# $list[0] is pattern
	# $list[1] is option i if it was given on the cmdline
	my $pattern = $list[0];
	my $option;
	$option = $list[1] if $list[1];

	# delete all lines that match address
	# if address is "" then delete all lines
	# copy non matching lines to new array
	# set efile = to new array
	# return no of lines deleted
	my @temparray = ();

	# reset count for no of lines deleted.
	my $count = 0;

	# for debug
	push @debug, "arg = $arg\n" if $DEBUG;

	# if modifier is i
	if (defined($option)) {
		if ($option =~ /i/) {
			for (my $i=0; $i<scalar(@efile); $i++) {
				# option i defined possibly e as well
				# case insensitive pattern
				if ($efile[$i] =~ /$pattern/i) {
					# delete line by not pushing it to @temparray
					# if modifier e given, delete following empty lines
					if ($option =~ "e") {
						# while lines are empty delete them
						# by moving not pushing them.
						# done by incrementing $i
						# do not go past end of file
						while ($i < scalar(@efile) - 1 and $efile[$i+1] =~ /^$/) {
							# skip this line
							$i++;
							
							# count the deleted lines
							$count++;
						}
						# DEBUG: print the line
						push @debug, "deleted: $efile[$i]\n" if $DEBUG;
						# delete line and count it
						$count++;
					}
				} else {
					# keep line
					push @temparray, $efile[$i];
				}
			}
		} elsif ($option =~ /e/) {
			for (my $i=0; $i<scalar(@efile); $i++) {
				# option e define and not i
				# case insensitive pattern
				if ($efile[$i] =~ /$pattern/) {
					# delete line by not pushing it to @temparray
					# if modifier e given, delete following empty lines
					# while lines are empty delete them
					# by moving not pushing them.
					# done by incrementing $i
					# do not go past end of file
					while ($i < scalar(@efile) - 1 and $efile[$i+1] =~ /^$/) {
						# skip this line empty line due to modifier e
						$i++;
						
						# count the deleted lines
						$count++;
					}
					# DEBUG: print the line
					push @debug, "deleted: $efile[$i]\n" if $DEBUG;
					# delete line and count it
					$count++;

				} else {
					# keep line
					push @temparray, $efile[$i];
				}
			}
		}

	} else {
		# $option is not defined no i or e
		for (my $i=0; $i<scalar(@efile); $i++) {
			# case sensitive search
			if ($efile[$i] =~ /$pattern/) {
				# DEBUG: print the line
				push @debug, "deleted: $efile[$i]\n" if $DEBUG;
				# delete line and count it
				$count++;
			} else {
				# keep line
				push @temparray, $efile[$i];
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
		print "##################################\n\n";
	}

	return $count;
}

################################################################################
# sub to subsitute in each line of the file
# parameters: 1. arg /pattern/replacement/ig or any combination of modifiers
# return: no of subsitutions
#         undefined on error
################################################################################
sub subst {
	# for debug
	my @debug = ("##################### StEdit->subst()#####################\n") if $DEBUG;

	# there must be 2 parameters passed
	my $self = shift;
	my $arg = shift;

	# list for all argument components
	# $list[0] = pattern
	# $list[1] = replacement
	# $list[2] = modiefies i or g or ig or gi or undef
	my @list;

	# parse argument
	$self->parsearg("s", $arg, \@list);

	# use nice var names
	my $pattern = $list[0];
	my $replacement = $list[1];
	my $modi = $list[2] if $list[2];
	# for debug
	do {
		if ($modi) {
			push @debug, "pattern = $pattern : replacement = $replacement : modifier = $modi\n";
		} else {
			push @debug, "pattern = $pattern : replacement = $replacement : no modifiers\n";
		}
	} if $DEBUG;
	
	# the modifier can be
	# i - case insensitive
	# g - global search in line
	# not just first occurence
	# search each line
	my $count = 0;
	my $noofmatches;
	# substitutions depend on the modifier
	# "" means no modifier

	# for debugging
	my $oldline if $DEBUG;

	# modi could be i or g or ig or gi or nothing
	if (defined($modi) and $modi eq "g") {
		# modifier = g
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$pattern/$replacement/g;
			#for debug
			push @debug, "old: $oldline\nnew: $line\n" if $DEBUG and ($noofmatches > 0);
			
			# add up matches
			$count = $count + $noofmatches;
		}
	} elsif (defined($modi) and $modi eq "i") {
		# modifier = i
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$pattern/$replacement/i;
			#for debug
			push @debug, "old: $oldline\nnew: $line\n" if $DEBUG and ($noofmatches > 0);
			
			$count = $count + $noofmatches;
		}
	} elsif (defined($modi) and ($modi =~ /i/ and $modi =~ /g/)) {
		# modifier = ig
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$pattern/$replacement/ig;
			#for debug
			push @debug, "old: $oldline\nnew: $line\n" if $DEBUG and ($noofmatches > 0);
			
			$count = $count + $noofmatches;
		}

	} else {
		# no modifier
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$pattern/$replacement/;
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

###########################################################################
# method to append a string to the end of a file
# parameters: 1 arg eg /text/
# return: 1 on success
#         undefined on error
##########################################################################
sub append {
	# for debug
	my @debug = ("######################## StEdit->append()########################\n") if $DEBUG;
	
	#get parameters
	my $count = scalar(@_);

	# for debug
	push @debug, "no of parameters = $count\n" if $DEBUG;
	
	if ($count != 2) {
		warn "append error: $count parameters passed";
		return;
	}

	# get arguments
	my $self = shift;
	my $arg = shift;

	# for debug
	push @debug, "text = $arg\n" if $DEBUG;
	
	# list for parsed arguments
	my @list;

	# parse the arg list
	$self->parsearg("a", $arg, \@list);
	
	# append the string to the efile array
	# string can be : something\nnew line\n\tnew line again\n\tetc
	push @efile, $list[0];

	# for debug
	if ($DEBUG) {
		foreach my $item (@debug) {
			print "$item";
		}
		print "#############################################\n\n";
	}

	
	return 1;
}

#######################################################################
# sub to insert a line after/before a line
# only invoked by StEdit->insert(). Not called by the user
# parameters: 1. ref to line
#             2. ref to text to insert
#             3. ref to temparray
#             4. modifier a or b , after or before for insert
# return: nothing
#######################################################################
sub insertline {

	# get parameters
	# ref to self
	# ref to line
	# ref to text
	# ref to temparray
	# modifiers
	my $self = shift;
	my $rline = shift;
	my $rtext = shift;
	my $rtemparray = shift;
	my $modi = shift;

	# for debugging
	my $dline if $DEBUG;
	
	# insert
	if (defined($modi) and $modi =~ /a/) {
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
#################################################################
# method to insert a string(s) in a file
# after or before a certain line.
# the default is insert before a line
# the pattern can have modifiers, i case insensitive
#                                 b before match
#                                 a after match
# parameters
#   1. arg eg /pattern/text/iab modifiers or none
# return: undefined on error
#          count  on success
#          0  on match not found
################################################################
sub insert {
	# for debug
	my @debug = ("################## StEdit->inser()t #########################\n") if $DEBUG;
	
	# get parameters
	my $self = shift;
	my $arg = shift;
	
	# list for components of arg
	my @list;
	
	# parse arguments
	$self->parsearg("i", $arg, \@list);
	
	my $pattern = $list[0];
	my $text = $list[1];
	
	# modifier could be i or a or b or ia or ib or nothing but not ab together
	my $modi = $list[2] if $list[2];
	my @temparray = ();
	
	# if modi contains valid modifiers
	if ($modi) {
		unless ($modi =~ /^i$|^b$|^a$|^ib$|^bi$|^ia$|^ai$/ or $modi eq "") {
			die "StEdit->insert(): Invalid modifier $modi";
		}
	}

	push @debug, "pattern = $pattern: modi = $modi\n" if $DEBUG;

	# insert text before/after case (in) sensitive to each matching line.
	# for all elements in list
	# no of insertions
	my $count = 0;
	foreach my $line (@efile) {
		# copy each line that does not match to temparray
		# when line matches insert before/after line in temparray
		if (defined($modi) and $modi =~ /i/) {
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
		print "###########################\n";
	}

	return $count;
}
	
# method to write file to disk
# if -b given a backup is also made
# parameters: optional file name, if no filename given and "backup" or "nobackup"
# write to original file
# return: nothing
sub write {
	my $count = scalar(@_);
	
	# get parameters
	my $self = shift @_;

	# file name, could be a new file
	# or original file. 
	my $writefile = shift @_;
	
	# get backup flag
	my $backup = shift @_;

	print "StEdit->write() filename: $writefile\n" if $DEBUG;

	# make a backup copy of the original file to fname.bak if -b switch given
	
	do {
		copy($fname, $fname . ".bak") or die "Copy of $fname to $fname" . ".bak failed: $!\n";
	} if $backup eq "backup";

	# write the efile to disk
	open (my $fh, ">", $writefile) or die "Could not open $writefile for writing: $!\n";

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
	print "##################### $fname /#######################\n";
	foreach my $line (@efile) {
		print "$line\n";
	}
	print "#####################################################\n\n";
}
# this is the last line of the module and must be here
1;
