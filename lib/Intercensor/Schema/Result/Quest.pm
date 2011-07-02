package Intercensor::Schema::Result::Quest;

use Moose;
use namespace::autoclean;

extends 'DBIx::Class::Core';

use CLASS;
use Class::Load qw(load_class);
use Intercensor::Quest::Generator;
use Intercensor::Quest::Verifier;

CLASS->load_components(qw(InflateColumn::Serializer Core));

CLASS->table('quests');
CLASS->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1
    },
    name => {
        data_type => 'char',
        size      => 60
    },
    description     => { data_type => 'text' },
    generator_class => {
        data_type   => 'varchar',
        size        => 50,
    },
    generator_args => {
        data_type        => 'text',
        serializer_class => 'JSON',
        is_nullable      => 1,
    },
    verifier_class => {
        data_type => 'varchar',
        size      => 50,
    },
    verifier_args => {
        data_type        => 'text',
        serializer_class => 'JSON',
        is_nullable      => 1,
    },
);
CLASS->set_primary_key(qw(id));
CLASS->add_unique_constraint( [qw(name)] );

CLASS->has_many( 'player_quests', 'Intercensor::Schema::Result::PlayerQuest',
    'quest_id' );
CLASS->many_to_many( 'players', 'player_quests', 'player' );

has 'generator' => (
    is  => 'ro',
    isa => 'Intercensor::Quest::Generator',
    init_arg => undef,
    lazy => 1,
    builder => '_build_generator',
    handles => 'Intercensor::Quest::Generator',
);

has 'verifier' => (
    is  => 'ro',
    isa => 'Intercensor::Quest::Verifier',
    init_arg => undef,
    lazy => 1,
    builder => '_build_verifier',
    handles => 'Intercensor::Quest::Verifier',
);

sub _build_generator {
    my ($self) = @_;
    my $class = 'Intercensor::Quest::Generator::' . $self->generator_class;
    load_class($class);
    return $class->new($self->generator_args // {});
}

sub _build_verifier {
    my ($self) = @_;
    my $class = 'Intercensor::Quest::Verifier::' . $self->verifier_class;
    load_class($class);
    return $class->new($self->verifier_args // {});
}

CLASS->meta->make_immutable(inline_constructor => 0);
