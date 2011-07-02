#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 5;
use Test::Moose;
use URI::file;

BEGIN {
    use_ok('Intercensor::Quest::Verifier::Eq');
}

my $verifier
    = Intercensor::Quest::Verifier::Eq->new( string => 'TEST STRING' );

does_ok( $verifier, 'Intercensor::Quest::Verifier' );

ok( $verifier->verify('TEST STRING'),   'correct answer' );
ok( !$verifier->verify('WRONG STRING'), 'wrong answer' );
ok( $verifier->verify('test string'),   'case insensitive' );
