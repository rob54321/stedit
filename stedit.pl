#!/usr/bin/perl
use strict;
use warnings;
use lib "$ENV{HOME}/stedit";
use StEdit;

my $eobject = StEdit->new("/home/robert/junk.txt");

my $count = $eobject->delete("^\/mnt\/ad64");
print "$count lines deleted\n";

$eobject->display();
