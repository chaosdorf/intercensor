package Intercensor::Challenge::99shutdown;

use Modern::Perl;
use base qw(Intercensor::Challenge);

sub id {
    '99shutdown';
}

sub name {
    'Shut Down';
}

sub description {
    '<p>Here is some text which describes <strong>SHUT DOWN</strong>
    length that this space can be completely flooded with useless
    blindtext.</p> <p>It must be assumed that there is such a large amount of
    text that it might completely overflow. Obviously the layout must not
    break!</p>';
}

1;
