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
    '<p>Here is some text which describes <strong>RECORD BREAKER</strong>
    length that this space can be completely flooded with useless
    blindtext.</p> <p>It must be assumed that there is such a large amount of
    text that it might completely overflow. Obviously the layout must not
    break!</p>';
}

1;
