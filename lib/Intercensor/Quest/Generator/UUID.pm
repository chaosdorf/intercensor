package Intercensor::Quest::Generator::UUID;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

with qw(Intercensor::Quest::Generator);

use CLASS;
use UUID::Tiny qw(create_uuid uuid_to_string);

sub generate {
    return uuid_to_string(create_uuid());
}

CLASS->meta->make_immutable();
