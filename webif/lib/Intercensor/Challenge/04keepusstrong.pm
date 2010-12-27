package Intercensor::Challenge::04keepusstrong;

use Modern::Perl;
use base qw(Intercensor::Challenge);
use XML::LibXML;
use LWP::Simple;

sub id {
    '04keepusstrong';
}

sub name {
    'Keep Us Strong';
}

sub description {
    'Wikileaks has released a large amount of US embassy cables. We need you to
    find the cable with reference number 08DHAKA856 and provide us with the
    name of the mentioned organization';
}

sub verify_answer {
    my ($self, $user_id, $answer) = @_;

    return (lc($answer) eq 'rapid action battalion');
}

1;
