#!/usr/bin/perl
use strict;
use warnings;
use lib "$ENV{HOME}/stedit";
use StEdit;

my $addr = "^thi\{3\}s";

my $eobject = StEdit->new("/home/robert/junk.txt");
print "######### original############\n";
$eobject->display();
print "##############################\n";

my $count = $eobject->delete($addr);
print "$count lines deleted\n";

$eobject->display();
print "##############################\n";

$count = $eobject->subst("one", "LLL");
print "$count subsitutions made\n";

$eobject->display();
print "##############################\n";
