#!/usr/bin/perl
use strict;
use warnings;
use lib "$ENV{HOME}/stedit";
use StEdit;

my $addr = "one\$";
my $patt = "this is\$";
my $repl = "Jkl";
my $modi = "ig";
my $count;

my $eobject = StEdit->new("/home/robert/junk.txt");
print "######### original############\n";
$eobject->display();
print "##############################\n";

$count = $eobject->delete();
print "$count lines deleted\n";
print "address = " . $addr . "\n";

$eobject->display();
print "##############################\n";

$count = $eobject->subst($patt);
print "$count subsitutions made\n";
print "pattern = " . $patt . "\n";

$eobject->display();
print "##############################\n";
