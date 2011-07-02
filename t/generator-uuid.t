#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;
use Test::Moose;

BEGIN {
    use_ok('Intercensor::Quest::Generator::UUID');
}

my $generator = Intercensor::Quest::Generator::UUID->new();
does_ok($generator, 'Intercensor::Quest::Generator');

is(length $generator->generate(), 36, 'generate returns UUID');
