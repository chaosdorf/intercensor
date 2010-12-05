package Intercensor::Webif;
use Modern::Perl;
use Dancer ':syntax';
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);
use Dancer::Plugin::Database;
use Data::Random qw(rand_chars);
use IPC::System::Simple qw(capture);

use Module::Pluggable
    search_path => ['Intercensor::Challenge'],
    instantiate => 'new',
    sub_name => 'challenges';

our $VERSION = '0.1';

my %challenges = map { $_->id => $_ } __PACKAGE__->challenges();

sub gensalt {
    return join(q{}, rand_chars(set => 'all', size => 16));
}

before sub {
    if (!session->{user} && request->path_info !~ m{^/(register|login)/?$}) {
        return redirect '/login';
    }

    my $ip = request->remote_address;

    my $ipsets;
    {
        # Workaround for https://rt.cpan.org/Public/Bug/Display.html?id=46684
        # in IPC::System::Simple
        local $SIG{CHLD} = 'DEFAULT';
        $ipsets = capture('sudo', 'ipset', '-S');
    }

    my ($cid) = ($ipsets =~ /^-A (\w+) \Q$ip\E$/gms);

    if ($cid) {
        var current_challenge => $challenges{$cid};
    }
};

before_template sub {
    my($tokens) = @_;
    $tokens->{current_challenge} = vars->{current_challenge};
    my @path = split(qr{/}, request->path);
    $tokens->{page} = $path[1];

    # ? + 0 is a workaround for
    # https://rt.cpan.org/Public/Bug/Display.html?id=29629
    my $res = database->selectall_arrayref(
        'SELECT challenge AS cid, solved_at
        FROM solved_challenges
        WHERE user_id = (? + 0)
        ORDER BY solved_at DESC
        LIMIT 5',
        { Slice => {} },
        session->{user}{id},
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

    $tokens->{latest_challenges} = \@latest_challenges;
};

get '/login' => sub {
    template 'login', {}, { layout => undef };
};

post '/login' => sub {
    my $row = database->selectrow_hashref(
        'SELECT id, password, salt FROM users WHERE username = ?',
        {},
        params->{username}
    );
    if ($row) {
        my $hash = en_base64(bcrypt_hash({
            key_nul => 1,
            cost => 8,
            salt => $row->{salt},
        }, params->{password}));

        if ($row->{password} eq $hash) {
            session user => {
                name => params->{username},
                id => $row->{id},
            };
            redirect '/';
            return;
        }
    }

    template 'login', {
        error => 'Wrong username or password',
    }, { layout => undef };
};

get '/logout' => sub {
    session user => undef;
    redirect '/';
};

get '/register' => sub {
    template 'register', {}, { layout => undef };
};

post '/register' => sub {
    my @errors;
    if (!params->{username}) {
        push @errors, 'Username missing';
    } elsif (params->{username} !~ /^\w+$/) {
        push @errors,
          'Username invalid. Only characters, digits and underscores are allowed';
    }

    if (!params->{password}) {
        push @errors, 'Password missing';
    } elsif (!params->{confirm}) {
        push @errors, 'Password confirmation missing';
    } elsif (params->{password} ne params->{confirm}) {
        push @errors, 'Password and password confirmation are not equal';
    }

    # Check for existing users
    my $row = database->selectrow_hashref(
        'SELECT id FROM users WHERE username = ?',
        {},
        params->{username}
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
        }, params->{password}));
        database->do(
            'INSERT INTO users (username, password, salt) VALUES (?, ?, ?)',
            {},
            params->{username},
            $hash,
            $salt,
        );
        session user_id => database->sqlite_last_insert_rowid();
        redirect '/';
    } else {
        template 'register', { errors => \@errors }, { layout => undef };
    }
};

get '/dashboard' => sub {
    template dashboard => {};
};

get '/challenges' => sub {

    my @rows = @{ database->selectcol_arrayref(
        'SELECT challenge FROM solved_challenges
        WHERE user_id = (? + 0)',
        {},
        session->{user}{id},
    ) };
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

    template challenges => {
        solved_challenges => \%solved,
        unsolved_challenges => \%unsolved,
    };
};

get '/challenge/:id' => sub {
    my $c = $challenges{ params->{id} };

    if ($c) {
        return template challenge => {
            challenge => $c,
        };
    }
    else {
        status 'not_found';
        return 'No such challenge';
    }
};

get '/' => sub {
    redirect '/dashboard';
};

true;
