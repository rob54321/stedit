#!/usr/bin/perl
use strict;
use warnings;
use lib "$ENV{HOME}/stedit";
use StEdit;

my $addr = "^thi\{3\}s";
my $patt = "this is\$";
my $repl = "Jkl";
my $modi = "g";

my $eobject = StEdit->new("/home/robert/junk.txt");
print "######### original############\n";
$eobject->display();
print "##############################\n";

my $count = $eobject->delete($addr);
print "$count lines deleted\n";
print "address = " . $addr . "\n";

$eobject->display();
print "##############################\n";

$count = $eobject->subst($patt, $repl, $modi);
print "$count subsitutions made\n";
print "pattern = " . $patt . "\n";

$eobject->display();
print "##############################\n";
