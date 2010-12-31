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
    return <<'EOF';
<p>Rien ne va plus. There are no designated solutions for this challenge.
can you still make it?</p>
EOF
}

sub verify_answer {
    0;
}

1;
