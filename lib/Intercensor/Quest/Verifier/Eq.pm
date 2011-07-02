package Intercensor::Quest::Verifier::Eq;
use CLASS;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

with qw(Intercensor::Quest::Verifier);

has string => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub verify {
    my ( $self, $answer ) = @_;

    return lc($answer) eq lc($self->string);
}

CLASS->meta->make_immutable();
