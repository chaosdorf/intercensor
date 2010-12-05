package Intercensor::Challenge::01recordbreaker;

use Modern::Perl;
use base qw(Intercensor::Challenge);

sub id {
    '01recordbreaker';
}

sub name {
    'Record Breaker';
}

sub description {
    '<p>Let\'s start with something simple. "Fefe\'s Blog" is a site well-known
    for spreading conspiracy theories and general non-conforming information.
    Because of this, access to it is prohibited</p>
    <p>Your task is to retrieve the latest blog headline and then give it to
    us.</p>';
}

1;
