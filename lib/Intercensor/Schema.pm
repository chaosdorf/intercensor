package Intercensor::Schema;

use Moose;
use namespace::autoclean;

extends 'DBIx::Class::Schema';

use CLASS;

CLASS->load_namespaces();

CLASS->meta->make_immutable();
