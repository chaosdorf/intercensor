package webif;
use Dancer ':syntax';
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64);
use Dancer::Plugin::Database;
use Data::Random qw(rand_chars);

our $VERSION = '0.1';

sub gensalt {
    return join(q{}, rand_chars(set => 'all', size => 16));
}

before sub {
    if (!session->{user_id} && request->path_info !~ m{^/(register|login)/?$}) {
        redirect '/login';
    }
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
            session user_id => $row->{id};
            redirect '/';
            return;
        }
    }

    template 'login', {
        error => 'Wrong username or password',
    }, { layout => undef };
};

get '/logout' => sub {
    session user_id => undef;
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

get '/' => sub {
    template 'index';
};

true;
