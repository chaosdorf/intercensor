#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 4;
use Test::Moose;
use URI::file;

BEGIN {
    use_ok('Intercensor::Quest::Verifier::Feed');
}

my $verifier = Intercensor::Quest::Verifier::Feed->new(
    uri => URI::file->new_abs('t/verifier-feed/rss.xml'),
);

does_ok( $verifier, 'Intercensor::Quest::Verifier' );

ok( $verifier->verify('TEST TITLE'),   'correct answer' );
ok( !$verifier->verify('WRONG TITLE'), 'wrong answer' );
