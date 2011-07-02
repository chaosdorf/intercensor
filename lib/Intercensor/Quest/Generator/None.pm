package Intercensor::Quest::Generator::None;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

with qw(Intercensor::Quest::Generator);

use CLASS;

sub generate {
    return undef;
}

CLASS->meta->make_immutable();
