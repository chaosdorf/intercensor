package Intercensor::User;
use Modern::Perl;
use autodie ':all';
use base qw(Class::Accessor::Fast);
use Authen::Passphrase::BlowfishCrypt;
use Carp;
use DateTime;
use DBI;
use Intercensor::Challenge;
use Intercensor::Util::Conntrack qw(delete_conntrack_states);
use Intercensor::Util::IPSet qw(find_ipset add_to_ipset delete_from_ipset);
use List::MoreUtils qw(uniq);
use Set::Object qw(set);

__PACKAGE__->mk_ro_accessors(qw(name id));

my $dbh = DBI->connect('dbi:Pg:dbname=intercensor', '', '', {RaiseError => 1});

sub validate_login {
    my ($self, $given) = @_;

    my $authpw
      = Authen::Passphrase::BlowfishCrypt->from_crypt($self->{password});

    return $authpw->match($given);
}

sub lookup {
    my ($class, %args) = @_;

    if ($args{name}) {
        my $row  = $dbh->selectrow_hashref(
            'SELECT * FROM users WHERE name = ?',
            {}, $args{name}
        );
        if ($row) {
            return bless $row, $class;
        }
        else {
            return;
        }
    }
    else {
        croak 'No filter argument for lookup given';
    }
}

sub create {
    my ($class, %args) = @_;

    my $authpw = Authen::Passphrase::BlowfishCrypt->new(
        cost        => 8,
        salt_random => 1,
        passphrase  => $args{password},
    );
    $dbh->do('INSERT INTO users (name, password) VALUES (?, ?)',
        {}, $args{name}, $authpw->as_crypt());
    my $id =  $dbh->last_insert_id(undef, undef, undef, undef,
                                   {sequence => 'users_id_seq'});

    my $self = {
        id => $id,
        name => $args{name},
    };
    return bless $self, $class;
}

sub address {
    my ($self, $address) = @_;

    if (@_ == 2) {
        $dbh->do('UPDATE users SET address = ? WHERE id = ?',
                 {}, $address, $self->id);
        $self->{address} = $address;
    }

    return $self->{address};
}

sub current_challenge {
    my ($self) = @_;
    my $cid = find_ipset($self->address);
    return Intercensor::Challenge->get($cid) if $cid;
    return;
}

sub stop_challenge {
    my ($self) = @_;
    if ($self->current_challenge) {
        delete_from_ipset($self->current_challenge->id, $self->address);
    }
}

sub start_challenge {
    my ($self, $challenge) = @_;
    $self->stop_challenge();
    add_to_ipset($challenge->id, $self->address);
    delete_conntrack_states($self->address);
}

sub solve_challenge {
    my ($self, $challenge) = @_;
    $dbh->do(
        'INSERT INTO solved_challenges
             (user_id, challenge_id, solved_at)
             VALUES (?, ?, ?)',
        {},
        $self->id,
        $challenge->id,
        DateTime->now(),
    );
    $self->stop_challenge();
}

sub solved_challenges {
    my ($self) = @_;
    my $rows_ref = $dbh->selectcol_arrayref(
        'SELECT challenge_id FROM solved_challenges
        WHERE user_id = ?',
        {},
        $self->id
    );

    return map { Intercensor::Challenge->get($_) } uniq @$rows_ref;
}

sub unsolved_challenges {
    my ($self) = @_;
    my $solved_ref = set($self->solved_challenges);
    my $all_ref = set(Intercensor::Challenge->all);

    return @{$all_ref - $solved_ref};
}

sub latest_solved_challenges {
    my ($self) = @_;

    my $rows_ref = $dbh->selectall_arrayref(
        'SELECT challenge_id AS cid, solved_at
        FROM solved_challenges
        WHERE user_id = ?
        ORDER BY solved_at DESC
        LIMIT 5',
        {Slice => {}},
        $self->id,
    );

    my @latest_challenges;
    foreach my $row (@$rows_ref) {
        my $id = $row->{cid};
        push @latest_challenges, {
            challenge => Intercensor::Challenge->get($id),
            solved_at => $row->{solved_at},
        };
    }
    return @latest_challenges;
}

1;
