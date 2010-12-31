package Intercensor::Challenge::03jabberbox;

use Modern::Perl;
use base qw(Intercensor::Challenge);
use XML::LibXML;
use LWP::Simple;

sub id {
    '03jabberbox';
}

sub name {
    'Jabber Box';
}

sub description {
    'JABBER BOX';
}

sub get_question {
    my ($self, $user_id) = @_;
    return $self->generate_token($user_id);
}

sub verify_answer {
    my ($self, $user_id, $answer) = @_;

    return 0;
}

1;
