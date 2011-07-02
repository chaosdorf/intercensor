package Intercensor::Schema::Result::PlayerQuest;

use Moose;
use namespace::autoclean;

extends 'DBIx::Class::Core';

use CLASS;

CLASS->load_components(qw(InflateColumn::DateTime));

CLASS->table('player_quests');
CLASS->add_columns(
    player_id => { data_type => 'integer' },
    quest_id  => { data_type => 'integer' },
    solved_at => {
        data_type => 'datetime',
        timezone  => 'local'
    },
    token => {
        is_nullable => 1,
        data_type   => 'text'
    },
);
CLASS->set_primary_key(qw(player_id quest_id));

CLASS->belongs_to( 'player', 'Intercensor::Schema::Result::Player',
    'player_id' );
CLASS->belongs_to( 'quest', 'Intercensor::Schema::Result::Quest',
    'quest_id' );

CLASS->meta->make_immutable(inline_constructor => 0);
