#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;
use Test::Moose;

BEGIN {
    use_ok('Intercensor::Quest::Generator::None');
}

my $generator = Intercensor::Quest::Generator::None->new();
does_ok($generator, 'Intercensor::Quest::Generator');

ok(!defined $generator->generate(), 'generate returns undef');
