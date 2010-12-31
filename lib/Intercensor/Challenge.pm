package Intercensor::Challenge;
use Modern::Perl;
use Digest::SHA qw(hmac_sha1_hex);

use Module::Pluggable
  search_path => ['Intercensor::Challenge'],
  instantiate => 'new',
  sub_name    => '_challenges';

my %challenges = map { $_->id => $_ } __PACKAGE__->_challenges('mysecret');

# Class methods

sub get {
    my ($class, $id) = @_;

    return $challenges{$id};
}

sub ids {
    return keys %challenges;
}

sub all {
    return values %challenges;
}

# Instance methods

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
