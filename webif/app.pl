#!/usr/bin/env perl
use Mojolicious::Lite;
use autodie ':all';
use lib 'lib';
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);
use Data::Random qw(rand_chars);
use DateTime;
use DBI;
use Intercensor::Util::Conntrack qw(delete_conntrack_states);
use IPC::System::Simple qw(capture);
use POSIX qw(strftime);

use Module::Pluggable
    search_path => ['Intercensor::Challenge'],
    instantiate => 'new',
    sub_name => 'challenges';

our $VERSION = '0.1';
my $dbh = DBI->connect('dbi:Pg:dbname=intercensor', '', '', {
    RaiseError => 1,
});

my %challenges = map { $_->id => $_ } __PACKAGE__->challenges('mysecret');

sub gensalt {
    return join(q{}, rand_chars(set => 'all', size => 16));
}

sub stop_challenge {
    my ($challenge, $ip) = @_;

    # Workaround for
    # https://rt.cpan.org/Public/Bug/Display.html?id=46684 in
    # IPC::System::Simple
    local $SIG{CHLD} = 'DEFAULT';

    if ($challenge) {
        system('sudo', 'ipset', '-D', $challenge->id, $ip);
    }
}

get '/about' => sub {
    my $self = shift;
    $self->render('about');
};

get '/login' => sub {
    my $self = shift;
    $self->render('login', error => undef);
} => 'login';

post '/login' => sub {
    my $self = shift;
    my $row = $dbh->selectrow_hashref(
        'SELECT id, password_hash, password_salt FROM users WHERE name = ?',
        {},
        $self->param('username'),
    );
    if ($row) {
        my $hash = en_base64(bcrypt_hash({
            key_nul => 1,
            cost => 8,
            salt => $row->{password_salt},
        }, $self->param('password')));

        if ($row->{password_hash} eq $hash) {
            $self->session(user => {
                name => $self->param('username'),
                id => $row->{id},
            });
            $self->redirect_to('/');
            return;
        }
    }

    $self->render('login', error => 'Wrong username or password');
};

get '/register' => sub {
    my $self = shift;
    $self->render('register', errors => []);
};

post '/register' => sub {
    my $self = shift;
    my @errors;
    my $username = $self->param('username');
    my $password = $self->param('password');
    my $confirm = $self->param('confirm');

    if (!$username) {
        push @errors, 'Username missing';
    } elsif ($username !~ /^\w+$/) {
        push @errors,
          'Username invalid. Only characters, digits and underscores are allowed';
    }

    if (!$password) {
        push @errors, 'Password missing';
    } elsif (!$confirm) {
        push @errors, 'Password confirmation missing';
    } elsif ($password ne $confirm) {
        push @errors, 'Password and password confirmation are not equal';
    }

    # Check for existing users
    my $row = $dbh->selectrow_hashref(
        'SELECT id FROM users WHERE name = ?',
        {},
        $username,
    );
    if ($row) {
        push @errors, 'A user with this username already exists';
    }

    if (!@errors) {
        my $salt = gensalt();
        my $hash = en_base64(bcrypt_hash({
            key_nul => 1,
            cost => 8,
            salt => $salt,
        }, $password));
        $dbh->do(
            'INSERT INTO users (name, password_hash, password_salt) VALUES (?, ?, ?)',
            {},
            $username,
            $hash,
            $salt,
        );
        $self->session(user => {
            id => $dbh->last_insert_id(undef, undef, undef, undef,
                                       {sequence => 'users_id_seq'}),
            name => $username,
        });
        $self->redirect_to('/');
    }
    else {
        $self->render('register', errors => \@errors);
    }
};


under sub {
    my $self = shift;
    if (! $self->session('user')) {
        $self->redirect_to('login');
        return;
    }

    $self->stash(current_username => $self->session('user')->{name});

    my $ip = $self->tx->remote_address;

    my $ipsets;
    {
        # Workaround for https://rt.cpan.org/Public/Bug/Display.html?id=46684
        # in IPC::System::Simple
        local $SIG{CHLD} = 'DEFAULT';
        $ipsets = capture('sudo', 'ipset', '-S');
    }

    my ($cid) = ($ipsets =~ /^-A (\w+) \Q$ip\E$/gms);

    if ($cid) {
        $self->stash(current_challenge => $challenges{$cid});
    }
    else {
        $self->stash(current_challenge => undef);
    }

    my $res = $dbh->selectall_arrayref(
        'SELECT challenge_id AS cid, solved_at
        FROM solved_challenges
        WHERE user_id = ?
        ORDER BY solved_at DESC
        LIMIT 5',
        { Slice => {} },
        $self->session('user')->{id},
    );

    my @latest_challenges;
    foreach my $row (@$res) {
        my $id = $row->{cid};
        push @latest_challenges, {
            id => $id,
            solved_at => $row->{solved_at},
            name => $challenges{$id}->name,
        };
    }

    $self->stash(latest_challenges => \@latest_challenges);

    $self->stash(just_solved => scalar $self->flash('just_solved'));

    return 1;
};

get '/logout' => sub {
    my $self = shift;
    $self->session(user => 0);
    $self->redirect_to('/');
};

get '/challenges' => sub {
    my $self = shift;
    my @rows = @{ $dbh->selectcol_arrayref(
        'SELECT challenge_id FROM solved_challenges
        WHERE user_id = ?',
        {},
        $self->session('user')->{id},
    )};
    my %is_solved = map { $_ => 1 } @rows;

    my (%solved, %unsolved);
    foreach my $id (keys %challenges) {
        if ($is_solved{$id}) {
            $solved{$id} = $challenges{$id};
        }
        else {
            $unsolved{$id} = $challenges{$id};
        }
    }

    $self->render('challenges',
        solved_challenges => \%solved,
        unsolved_challenges => \%unsolved,
        page_title => 'Challenges',
    );
};

get '/challenge/:id' => sub {
    my $self = shift;
    my $c = $challenges{ $self->param('id') };

    if ($c) {
        my $question;
        if (defined($self->stash('current_challenge')) and
            $c == $self->stash('current_challenge'))
        {
            $question = $c->get_question($self->session('user')->{id});
        }

        $self->render('challenge',
            challenge => $c,
            page_title => $c->name . ' Challenge',
            question => $question,
            error => undef,
        );
    }
    else {
        $self->render(text => 'Not Found', status => 404);
    }
};

post '/challenge/:id/play' => sub {
    my $self = shift;
    my $c = $challenges{ $self->param('id') };

    if ($c) {
        #debug sprintf('User %s starting challenge %s', $self->session('user')->{name}, $self->param('id'));

        {
            # Workaround for
            # https://rt.cpan.org/Public/Bug/Display.html?id=46684 in
            # IPC::System::Simple
            local $SIG{CHLD} = 'DEFAULT';

            stop_challenge($self->stash('current_challenge'), $self->tx->remote_address);
            system('sudo', 'ipset', '-A', $c->id, $self->tx->remote_address);

            delete_conntrack_states($self->tx->remote_address);
        }
        $self->redirect_to('/challenge/' . $c->id);
    }
    else {
        $self->render(text => 'No such challenge', status => 404);
    }
};

post '/challenge/:id/stop' => sub {
    my $self = shift;
    my $c = $challenges{ $self->param('id') };

    if ($c) {
        #debug sprintf('User %s stopping challenge %s', $self->session('user')->{name}, $self->param('id'));
        stop_challenge($self->stash('current_challenge'), $self->tx->remote_address);
        $self->redirect_to('/challenges');
    }
    else {
        $self->render(text => 'No such challenge', status => 404);
    }
};

post '/challenge/:id/solve' => sub {
    my $self = shift;
    my $c = $challenges{ $self->param('id') };

    if ($c) {
        my $a = $self->param('answer');

        #debug sprintf('User %s solving challenge %s: %s', $self->session('user')->{name}, $self->param('id'), $a);

        if ($c->verify_answer($self->session('user')->{id}, $a)) {
            $dbh->do('INSERT INTO solved_challenges
                     (user_id, challenge_id, solved_at)
                     VALUES (?, ?, ?)',
                     {},
                     $self->session('user')->{id},
                     $c->id,
                     DateTime->now(),
            );
            stop_challenge($self->stash('current_challenge'), $self->tx->remote_address);

            #debug sprintf('User %s solved challenge %s', $self->session('user')->{name}, $self->param('id'));

            $self->flash(just_solved => $c->name);
            $self->redirect_to('/challenges');
        }
        else {
            #debug sprintf('User %s failed to solve challenge %s', $self->session('user')->{name}, $self->param('id'));

            $self->render('challenge',
                challenge => $c,
                page_title => $c->name . ' Challenge',
                error => 'Your answer is wrong',
                question => $c->get_question($self->session('user')->{id}),
            );
        }
    }
    else {
        $self->render(text => 'No such challenge', status => 404);
    }
};

get '/' => sub {
    my $self = shift;
    if (my $c = $self->stash('current_challenge')) {
        $self->redirect_to('/challenge/' . $c->id);
    }
    else {
        $self->redirect_to('/challenges');
    }
};
#
app->start;
