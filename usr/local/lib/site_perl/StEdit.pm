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

# file name of file to be edited
my $fname;

# array to hold the original file
# so that it can be displayed in colour
# to indicate the changes made.
my @ofile = ();
# array to hold the edited file line by line.

my @efile = ();

# records of the original file
# index => [colour, lineref]
my %file;

# index for no of lines in a file
# starts from 0
my $maxIndex;

# the colours used for display the file
# to indicate changes.
# red: line deleted
# green: line added by append or insert
# yellow: line was changed by subst command
my $red = "\e[31m";
my $green = "\e[32m";
my $yellow = "\e[33m";
my $blue = "\e[34m";
my $magenta = "\e[35m";
my $cyan = "\e[36m";
my $normal = "\e[0m";

# used to mark empty deleted lines
my $redunderscore = "\e[31m____";

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
	# i is for the index
	my $i = 0;
	while (my $line = <$fh>) {
		# remove terminator at end
		chomp($line);
		# add to array
		push (@efile, $line);

		# setup the hash with records of the original file
		# format index => [colour, line]
		# colour is n - normal, r - red, g - green, y - yellow, b - blue
		$file{$i} = ["", $line];

		# increment i for the next line
		$i++;
	}

	# set the max index for the file
	$maxIndex = $i - 1;

	# close file
	close $fh;
	
	my $self = {};
	bless $self, $class;
	return $self;
}

####################################################
# script method
# this method applies each command from a script file
# to the file being edited.
# parameters: script file
# return: none
####################################################
sub script {
	# get parameters
	my $self = shift @_;
	my $sfile = shift @_;
	
	print "StEdit->script(): script file $sfile\n";
	
	# open file and read lines into an array
	open my $sf, "<", $sfile or die "Could not open script file $sfile: $!\n";
	
	# read into an array
	my @script = <$sf>;
	# remove terminator from each element
	chomp @script;
	
	close $sf;
	
	# make a list of commands/parameters @cmdlist, like @ARGV. (switch,param,switch,switch,param,....)
	my @cmdlist;
	my $cmd;
	my $param;
	
	# backup flag for write command
	my $backup = 0;

	# apply all commands in @script
	# to @efile as file to be edited is in @efile
	for ( my $i=0; $i<scalar(@script); $i++) {
		# each line is a command of form
		# -a /text/
		# -d /pattern/ie
		# -i /pattern/text/iab
		# -s /pattern/replacement/ig
		# -w optional filename -- this should be ignored
		# -l
		# make a list like @ARGV, ie (-i, "/pattern/text/ie", -d, "/pattern/ie", .., command, parameter, ..)
		# if a command has no parameter then command is followed by another command
		# or it is the last switch in the list.

		# @script is a list of lines of the script file
		# each line consists of
		# 1 command parameter
		# 2 command
		# empty lines
		# lines with spaces
		# get the command which could be -a -d -i -s -l -w
		# only -l does not take a parameter
		# =w may or may not take a parameter which is a file name
		# ignored, empty lines, lines with no command, white space, comment lines starting with #
		if ($script[$i] =~ /(-a|-d|-i|-s)/) {
			# there is a command
			# that takes a parameter
			$cmd = $1;
			$script[$i] =~ /(-.)\s+(.*)/;
			# if no parameter, die
			die "$cmd needs a parameter\n" unless $2;
			$param = $2;
			# clean up white space
			$param =~ s/(\s+)$//g;
			# push cmd and param onto list
			push @cmdlist, ($cmd, $param);
			
		} elsif ($script[$i] =~ /-l/) {
			# command -l does not take a parameter;
			push @cmdlist, "-l";

		} elsif ($script[$i] =~ /-w/) {
			# -w may or may not take a file name parameter
			$cmd = "-w";
			# check for a parameter after -w
			$script[$i] =~ /(-.)\s+(.*)/;
			# if there is parameter
			if (defined $2) {
				# clean white space after parameter
				$param = $2;
				$param =~ s/(\s+)$//g;
				# check $param is not the empty string
				if ($param ne "") {
					# push cmd and param on cmdlist
					push @cmdlist, ($cmd, $param);
					
			    } else {
					# there is no parameter
					push @cmdlist, "-w";
				}
			} else {
				# no parameter
				push @cmdlist, "-w";
			}
		} elsif ($script[$i] =~ /-b/) {
			# backup given for write command
			# set backup flag
			$backup = 1;
		}

	}	
	# for debug
	do {
		for (my $i=0; $i<scalar(@cmdlist); $i++) {
			print "cmdlist[$i] = [$cmdlist[$i]]\n";
		}
		print "backup flag = $backup\n";
	} if $DEBUG;

	# @cmdlist = (-a, /text/, -l, -i, /patten/text/ia, ...)
	# for each command call appropriate method
	# the write command is ignored
	for (my $i=0; $i<scalar(@cmdlist); $i++) {
		SWITCH: {
					$cmdlist[$i] =~ /-a/ && do {	# append command needs a parameter
													# if on last element, then no parameter follows
													if ($i < scalar(@cmdlist) - 1 and $cmdlist[$i+1] !~ /^-/) {
														$self->append($cmdlist[$i+1]);
														$i++;
														last SWITCH;
													} else {
														# no parameter found for -a
														# die
														die "-a from script file $sfile has no parameter\n";
													}
												};

					$cmdlist[$i] =~ /-d/ && do {	# delete command needs a parameter
													# die if no parameter for -d
													if ($i < scalar(@cmdlist) - 1 and $cmdlist[$i+1] !~ /^-/) {
														$self->delete($cmdlist[$i+1]);
														$i++;
														last SWITCH;
													} else {
														# no parameter for -d, die
														die "-d from script file $sfile has no parameter\n";
													}
												};
												
					$cmdlist[$i] =~ /-i/ && do {	#insert must have a parameter, die if not
													if ($i < scalar(@cmdlist) - 1 and $cmdlist[$i+1] !~ /^-/) {
														$self->insert($cmdlist[$i+1]);
														$i++;
														last SWITCH;
													} else {
														# no parameter found die
														die "-i from script file $sfile has no parameter\n";
													}
												};
												
					$cmdlist[$i] =~ /-s/ && do {	#subs must have a parameter, die if not
													if ($i < scalar(@cmdlist) - 1 and $cmdlist[$i+1] !~ /^-/) {
														$self->subst($cmdlist[$i+1]);
														$i++;
														last SWITCH;
													} else {
														# no parameter found die
														die "-s from script file $sfile has no parameter\n";
													}
												};
												
					$cmdlist[$i] =~ /-l/ && do {	# display the file, no parameter required
													$self->display();
													last SWITCH;
												};

					$cmdlist[$i] =~ /-w/ && do {	#write takes a filename parameter and backup or nobackup
													# and if -b  given then backup original file
													if ($i < scalar(@cmdlist) - 1 and $cmdlist[$i+1] !~ /^-/) {
														$self->write($cmdlist[$i+1], $backup);
														$i++;
														last SWITCH;
													} else {
														# no parameter use original file name
														$self->write($fname, $backup);
														
													}
												};
				}
	}

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

	if ($cmd eq "a" || $cmd eq "d") {
		# append /some text /
		# delete /some text /i i is optional modifier
		# stript components
		$arg =~ /\/(.*)\/(.*)/;
		
		$reflist->[0] = $1;
		if ($2) { $reflist->[1] = $2; } else { $reflist->[1] = ""; }

	} elsif ($cmd eq "i" || $cmd eq "s") {
		# insert and subst
		# take parameter /pattern/text/iabg optional modifiers
		$arg =~ /\/(.*)\/(.*)\/(.*)/;
		$reflist ->[0] = $1;
		if ($2) { $reflist->[1] = $2; } else { $reflist->[1] = ""; }
		
		if ($3) { $reflist->[2] = $3; } else { $reflist->[2] = ""; }
		
	}

	# print all arguments form @list
	do {
		print "################StEdit->parsearg()######################\n";
		print "command $cmd: no of reflist args ". scalar(@$reflist) . "\n";
		for (my $i=0; $i<scalar(@$reflist); $i++) {
			print "reflist[$i]: [$reflist->[$i]]\n" if $reflist->[$i];
		}
		print "################################################\n\n";
	} if $DEBUG;
	# check that the arg is not mal formed
	die "StEdit->parsarg(): The arg = $arg for command $cmd is malformed\n" if scalar(@$reflist) == 0 or ! defined($reflist->[0]);

}
####################################################################
# sub to insert a record into the hash %file.
# The modifier a | b (= default) will insert after
# or before.
# %file = (index => [colour, line])
# parameters: index of matching line
#             modifier, a or b or empty
#             line to be inserted
# return: nothing
####################################################################
sub hinsert {
	# get parameters
	my $self = shift @_;
	my $index = shift @_;
	my $mod = shift @_;
	my $line = shift @_;
	
	if ((defined($mod)) and ($mod ne "a")) {
		# default insert or b
		# line goes before matching line
		# copy lines to next line starting at bottom
		# insert the new line with colour green
		for (my $i=$maxIndex; $i<=$index; $i--) {
			# copy whole record
			$file{$i+1} = $file{$i};
		}
		
		# insert the new line
		$file{$index}->[0] = $green;
		$file{$index}->[1] = $line;
	}
}
		
####################################################################
# setcolour
# this method sets the colour in the original file
# red deleted line
# green for added line by insert or append
# yellow for line changed by subst
# append command has the correct index. search not necessary
# parameters: pattern to match, modifier, command a or i s d, new text|replacement text
# return: nothing
####################################################################
sub setcolour {
	# get parameters
	my $self = shift @_;
	my $pattern = shift @_;
	my $mod = shift @_;
	my $command = shift @_;
	my $text = shift @_;
	
	# find the line that matches the pattern
	if ($command eq "d") {
		# search for the pattern in ofile
		# and mark all with the colour

		for (my $i = 0; $i<= $maxIndex; $i++) {
			if (defined($mod) and $mod =~ /i/) {
				
				# modifier contains i
				if ($file{$i}->[1] =~ /$pattern/i) {
					$file{$i}->[0] = $red;

					# if e was given as well mark all following
					# empty lines with ____ in red
					if (defined($mod) and $mod =~ /e/) {
						while ($i<$maxIndex and $file{$i+1}->[1] =~ /^$/) {
							# mark with red ____
							$file{$i+1}->[0] = $redunderscore;
							# increase i
							$i++;
						}
					}
				}

			} else {
				# no i modifier
				if ($file{$i}->[1] =~ /$pattern/) {
					$file{$i}->[0] = $red;

					# if e was given as well mark all following
					# empty lines with ____ in red
					if (defined($mod) and $mod =~ /e/) {
						while ($i<$maxIndex and $file{$i+1}->[1] =~ /^$/) {
							# mark with red ____
							$file{$i+1}->[0] = $redunderscore;
							# increase i
							$i++;
						}
					}

				}
			}
		}
	} elsif ($command eq "a") {
		# there is no pattern or modifier for append
		# the new line has already been appended to ofile
		# set the colour
		# append the new text first
		$file{++$maxIndex}->[0] = $green;
		$file{$maxIndex}->[1] = $text;

	} elsif ($command eq "i") {
		for (my $i=0; $i<=$maxIndex; $i++) {
			# modifier could be i or a or b. b is default
			# only i is present, insert before
			if (defined($mod) and $mod =~ /i/) {
				# mod is i or ib. b is the default
				if ($mod !~ /a/) {
					
					# ignore delete lines in red
					if (($file{$i}->[1] =~ /$pattern/i) and ($file{$i}->[0] ne $red)) {
						# the line matches
						# insert the text before the line
						# move the matching line and successive lines down
						$self->hinsert($i, "b", $file{$i}->[1]);
					}
				} else {
					# mod is ai
					if ($ofile[$i] =~ /$pattern/i) {
						# the line matches
						# insert the text after the line
						# only if the line has not been deleted.
						if ($ofile[$i] !~ /^\e.31m/) {
							splice @ofile, $i+1, 0, $text;
							# set colour
#							$ofile[$i+1] = $colour . $ofile[$i+1] . $normal;
							# increase i to skip over inserted line
							$i++;
						}
					}
				}
			} elsif (defined($mod) and $mod =~ /a/) {
				# mod is a only
				# insert line after matched line
				if ($ofile[$i] =~ /$pattern/) {
					# the line matches
					# insert the text after the line
					# only if the line has not been deleted
					if ($ofile[$i] !~ /^\e.31m/) {
						splice @ofile, $i+1, 0, $text;
						# set colour
#						$ofile[$i+1] = $colour . $ofile[$i+1] . $normal;
						# increase i to skip over inserted line
						$i++;
					}
				}
			} else {
				# there is no mod
				if ($ofile[$i] =~ /$pattern/) {
					# the line matches
					# insert the text before the line
					# only if the line has not been deleted
					if ($ofile[$i] !~ /^\e.31m/) {
						splice @ofile, $i, 0, $text;
						# set colour
#						$ofile[$i] = $colour . $ofile[$i] . $normal;
						# increase i to skip over inserted line
						$i++;
					}
				}
			}

		}
	} elsif ($command eq "s") {
		# subst command, modifiers are i or g or nothing
		for (my $i=0; $i<scalar(@ofile); $i++) {
			# find matching line only if it was
			# not deleted.
			if ($ofile[$i] !~ /^\e.31m/) {
				# check modifier
				if (defined($mod) and ($mod eq "i")) {
					# matching line
					if ($ofile[$i] =~ /$pattern/i) {
						$ofile[$i] =~ s/$pattern/$text/i;
						# set colour
#						$ofile[$i] = $colour . $ofile[$i] . $normal;
					}	
				} elsif (defined($mod) and ($mod eq "ig" or $mod eq "gi")) {
					# matching line modifier is ig
					if ($ofile[$i] =~ /$pattern/i) {
						$ofile[$i] =~ s/$pattern/$text/ig;
						# set colour
#						$ofile[$i] = $colour . $ofile[$i] . $normal;
					}
				} elsif (defined($mod) and ($mod eq "g")) {
					# matching line modifier is ig
					if ($ofile[$i] =~ /$pattern/) {
						$ofile[$i] =~ s/$pattern/$text/g;
						# set colour
#						$ofile[$i] = $colour . $ofile[$i] . $normal;
					}
				} else {
					# matching line modifier no mofifier
					if ($ofile[$i] =~ /$pattern/) {
						$ofile[$i] =~ s/$pattern/$text/;
						# set colour
#						$ofile[$i] = $colour . $ofile[$i] . $normal;
					}
				}
			}
		}
	}
	return;
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

	# line number deleted for DEBUG
	my $lineno if $DEBUG;

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
					# set the colour to red in ofile
#					$self->setcolour($pattern, "i", $red, "d");

					# if modifier e given, delete following empty lines
					if ($option =~ "e") {
						# while lines are empty delete them
						# by not pushing them.
						# done by incrementing $i
						# do not go past end of file
						while ($i < scalar(@efile) - 1 and $efile[$i+1] =~ /^$/) {
							
							# DEBUG: print the line
							do {
								$lineno = $i + 1;
								push @debug, "deleted line $lineno: $efile[$i]\n";
							} if $DEBUG;
							# delete line and count it
							# count the deleted lines
							$count++;
							# skip this line
							
							# mark this empty line with red ___ in ofile
#							$pattern = "^\$";
#							$self->setcolour($pattern, "", $redunderscore, "d");
							$i++;
						}
					}
					
					# DEBUG: print the line
					do {
						$lineno = $i + 1;
						push @debug, "deleted line $lineno: $efile[$i]\n";
					} if $DEBUG;
					# delete line and count it
					$count++;

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
					# set colour of deleted line to red
#					$self->setcolour($pattern, "", $red, "d");
					
					# do not go past end of file
					while ($i < scalar(@efile) - 1 and $efile[$i+1] =~ /^$/) {
						
						# DEBUG: print the line
						do {
							$lineno = $i + 1;
							push @debug, "deleted line $lineno: $efile[$i]\n";
						} if $DEBUG;
						# delete line and count it
						# count the deleted lines
						$count++;
						
						# mark empty deleted line with red ___
#						$pattern = "^\$";
#						$self->setcolour($pattern, "", $redunderscore, "d");
						# skip this line empty line due to modifier e
						$i++;
					}
					# DEBUG: print the line
					do {
						$lineno = $i + 1;
						push @debug, "deleted line $lineno: $efile[$i]\n";
					} if $DEBUG;
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
				
				# mark the matching line(s)
				# in ofile as red.
#				$self->setcolour($pattern, "", $red, "d");
				
				# DEBUG: print the line
				do {
					$lineno = $i + 1;
					push @debug, "deleted line $lineno: $efile[$i]\n";
				} if $DEBUG;
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
	# set the colour of the deleted lines
	$self->setcolour($pattern, $option, "d");
	return $count;
}

################################################################################
# sub to subsitute in each line of the file
# parameters: 1. arg of form: /pattern/replacement/ig or any combination of modifiers
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
	# $list[2] = modifiers i or g or ig or gi or undef
	my @list;

	# parse argument
	# separate pattern, replacement, modifiers into a list
	$self->parsearg("s", $arg, \@list);

	# use nice var names
	my $pattern = $list[0];
	my $replacement = $list[1];
	my $modi = $list[2] if $list[2];
	# for debug
	do {
		if ($modi) {
			push @debug, "pattern = [$pattern] : replacement = [$replacement] : modifier = [$modi]\n";
		} else {
			push @debug, "pattern = [$pattern] : replacement = [$replacement] : no modifiers\n";
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
			push @debug, "old: [$oldline]\nnew: [$line]\n" if $DEBUG and ($noofmatches > 0);
			
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
			push @debug, "old: [$oldline]\nnew: [$line]\n" if $DEBUG and ($noofmatches > 0);
			
			$count = $count + $noofmatches;
		}
	} elsif (defined($modi) and ($modi =~ /i/ and $modi =~ /g/)) {
		# modifier = ig
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$pattern/$replacement/ig;
			#for debug
			push @debug, "old: [$oldline]\nnew: [$line]\n" if $DEBUG and ($noofmatches > 0);
			
			$count = $count + $noofmatches;
		}

	} else {
		# no modifier
		foreach my $line (@efile) {
			# for debug
			$oldline = $line if $DEBUG;
			$noofmatches = $line =~ s/$pattern/$replacement/;
			#for debug
			push @debug, "old: [$oldline]\nnew: [$line]\n" if $DEBUG and ($noofmatches > 0);
			
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

	# set colours in ofile
#	$self->setcolour($pattern, $modi, $yellow, "s", $replacement);
	
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
	# no pattern or modifier for append
	# include text to be appended
	$self->setcolour("", "", "a", $list[0]);
	
	return 1;
}

#######################################################################
# sub to insert a line after/before a line
# only invoked by StEdit->insert(). Not called by the user
# parameters: 1. ref to line
#             2. ref to text to insert
#             3. ref to temparray
#             4. modifier a or b , after or before for insert
#             5. index of changed line so ofile can updated for colour display
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
	my $index = shift;

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
		# insert text before a line - default
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
	for (my $i=0; $i<scalar(@efile); $i++) {
		# copy each line that does not match to temparray
		# when line matches insert before/after line in temparray
		if (defined($modi) and $modi =~ /i/) {
			# check for match
			if ($efile[$i] !~ /$pattern/i) {
				# no match , copy line
				push @temparray, $efile[$i];
			} else {
				# line does match.
				# insert text before or after
				# the index is used so ofile can be updated
				# to indicate colour changes
				$self->insertline(\$efile[$i], \$text, \@temparray, $modi, $i);

				# count insertions
				$count++;
			}
		} else {
			# no i modifier
			# check for match
			if ($efile[$i] !~ /$pattern/) {
				# no match , copy line
				push @temparray, $efile[$i];
			} else {
				# line does match.
				# insert text before -- default
				$self->insertline(\$efile[$i], \$text, \@temparray, $modi, $i);

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
	# set colour in ofile
#	$self->setcolour($pattern, $modi, $green, "i", $text);
	return $count;
}
	
# method to write file to disk
# if -b given a backup is also made
# parameters: filename to write to, could be original file
#             backup flag, backup if set
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
	} if ($backup);

	# write the efile to disk
	open (my $fh, ">", $writefile) or die "Could not open $writefile for writing: $!\n";

	foreach my $line (@efile) {
		print $fh "$line\n";
	}

	# close file
	close $fh;
}
	
###################################################################
# display the edited file
# parameters: none
# return: nothing
###################################################################
sub display {
	my $self = shift;

	# print each line
	print "##################### $fname /#######################\n";
	foreach my $line (@efile) {
		print "$line\n";
	}
	print "#####################################################\n\n";
}

###################################################################
# display the original file with colour indicators
# parameters: none
# return: nothing
###################################################################
sub cdisplay {
	my $self = shift;

	# print each line
	print "##################### $fname /#######################\n";
	for (my $i=0; $i<=$maxIndex; $i++) {
		# print each line in the colour in the record
		my $colour = $file{$i}->[0];
		my $cline = $colour . $file{$i}->[1] . $normal;
		print "$cline\n";
	}
	print "#####################################################\n\n";
}

# this is the last line of the module and must be here
1;
