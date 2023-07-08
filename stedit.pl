#!/usr/bin/perl
use strict;
use warnings;
use lib "usr/local/lib/site_perl";
use StEdit;

my $addr = "ONE\$";
my $patt = "^this";
my $repl = "TTHHIISS";
my $modi = "i";
my $count;

my $eobject = StEdit->new("/home/robert/junk.txt");

#$count = $eobject->delete($addr, $modi);

# $eobject->write();

#$count = $eobject->subst($patt, $repl, "g");


my $text = "second last line\n\tvery last line\n\t===============\n";
#$eobject->append("third\n\tsecond\n\tlast\n");

$eobject->insert("^one", "new inserted string==============", "i");
$eobject->write("/home/robert/silly.txt");
