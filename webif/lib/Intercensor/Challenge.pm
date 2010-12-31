package Intercensor::Challenge;
use Modern::Perl;
use Digest::SHA qw(hmac_sha1_hex);

sub new {
    my ($class, $secret) = @_;
    return bless {secret => $secret}, $class;
}

sub generate_token {
    my ($self, $user_id) = @_;

    return hmac_sha1_hex("$user_id!!" . $self->id, $self->{secret});
}

sub get_question {
    undef;
}

1;
