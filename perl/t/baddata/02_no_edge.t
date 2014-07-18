#!/usr/bin/perl  -I../../blib/lib -I../../blib/arch

## test the no XDI line bad data example

use Test::More tests => 5;

use strict;
use warnings;
use File::Basename;
use File::Spec;

my $epsi = 0.001;

BEGIN { use_ok('Xray::XDI') };

my $here = dirname($0);
my $file = File::Spec->catfile($here, '..', '..', '..', 'baddata', 'bad_02.xdi');
my $xdi  = Xray::XDI->new(file=>$file);

ok(($xdi->warning and $xdi->ok), 'bad_02.xdi flagged with a warning');
ok(($xdi->error =~ m{no element\.edge}), 'correctly identified missing edge symbol');


$file = File::Spec->catfile($here, '..', '..', '..', 'baddata', 'bad_04.xdi');
$xdi  = Xray::XDI->new(file=>$file);

ok(($xdi->warning and $xdi->ok), 'bad_04.xdi flagged with a warning');
ok(($xdi->error =~ m{no element\.edge}), 'correctly identified invalid edge symbol');

open(my $COV, '>>', 'coverage.txt');
print $COV 2, $/;
print $COV 4, $/;
close $COV;
