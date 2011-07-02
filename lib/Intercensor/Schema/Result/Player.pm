package Intercensor::Schema::Result::Player;

use Moose;
use namespace::autoclean;

extends 'DBIx::Class::Core';

use CLASS;

CLASS->load_components(qw(EncodedColumn));

CLASS->table('players');
CLASS->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1
    },
    name => {
        data_type => 'char',
        size      => 40
    },
    address => {
        data_type   => 'char',
        size        => 15,
        is_nullable => 1,
    },
    password => {
        data_type     => 'char',
        size          => 59,
        encode_column => 1,
        encode_class  => 'Crypt::Eksblowfish::Bcrypt',
        encode_args   => {
            key_nul => 0,
            cost    => 8
        },
        encode_check_method => 'check_password',
    },
);
CLASS->set_primary_key(qw(id));
CLASS->add_unique_constraint( [qw(name)] );

CLASS->has_many( 'player_quests',
    'Intercensor::Schema::Result::PlayerQuest', 'player_id' );
CLASS->many_to_many( 'quests', 'player_quests', 'quest' );

CLASS->meta->make_immutable(inline_constructor => 0);
