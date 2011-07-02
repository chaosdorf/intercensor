package Intercensor::Quest::Verifier::Feed;
use CLASS;
use Carp qw(confess);
use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::URI qw(Uri);
use namespace::autoclean;
use XML::Feed;

with qw(Intercensor::Quest::Verifier);

has uri => (
    is       => 'ro',
    isa      => Uri,
    required => 1,
    coerce   => 1,
);

sub verify {
    my ( $self, $answer ) = @_;

    my $feed = XML::Feed->parse( $self->uri ) or confess XML::Feed->errstr;
    my $title = [$feed->entries]->[0]->title;

    s/[^A-Za-z]//g for ($answer, $title);

    return $answer eq $title;
}

CLASS->meta->make_immutable();
