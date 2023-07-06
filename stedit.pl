#!/usr/bin/perl
use strict;
use warnings;
use lib "$ENV{HOME}/stedit";
use StEdit;

my $addr = "ONE\$";
my $patt = "^this";
my $repl = "TTHHIISS";
my $modi = "i";
my $count;

my $eobject = StEdit->new("/home/robert/junk.txt");
print "######### original############\n";
$eobject->display();
print "##############################\n";

$count = $eobject->delete($addr, $modi);

$eobject->display();
print "##############################\n";

# $eobject->write();

$count = $eobject->subst($patt, $repl, $modi);

$eobject->display();
print "##############################\n";

$eobject->append("/mnt/ad64", "i");

