#!/usr/bin/env perl
use Modern::Perl;
use Mojolicious::Lite;
use autodie ':all';
use lib '../lib';
use Intercensor::Challenge;
use Intercensor::User;
use IPC::System::Simple qw(capture);
use POSIX qw(strftime);

our $VERSION = '0.1';

get '/about' => 'about';

get '/login' => sub {
    my $self = shift;
    $self->render('login', error => undef);
} => 'login';

post '/login' => sub {
    my $self = shift;
    my $user = Intercensor::User->lookup(name => $self->param('username'));

    if ($user && $user->validate_login($self->param('password'))) {
        $self->session(user => $user);
        $self->redirect_to('/');
    }
    else {
        $self->render('login', error => 'Wrong username or password');
    }
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
    my $confirm  = $self->param('confirm');

    if (!$username) {
        push @errors, 'Username missing';
    }
    elsif ($username !~ /^\w+$/) {
        push @errors,
'Username invalid. Only characters, digits and underscores are allowed';
    }

    if (!$password) {
        push @errors, 'Password missing';
    }
    elsif (!$confirm) {
        push @errors, 'Password confirmation missing';
    }
    elsif ($password ne $confirm) {
        push @errors, 'Password and password confirmation are not equal';
    }

    # Check for existing users
    if (Intercensor::User->lookup(name => $username)) {
        push @errors, 'A user with this username already exists';
    }

    if (!@errors) {
        my $user = Intercensor::User->create(
            name => $username,
            password => $password,
        );
        $self->session(user => $user);
        $self->redirect_to('/');
    }
    else {
        $self->render('register', errors => \@errors);
    }
};

under sub {
    my $self = shift;
    my $user = $self->session('user');
    if (!$user) {
        $self->redirect_to('login');
        return;
    }

    $user->address($self->tx->remote_address);

    $self->stash(current_username => $self->session('user')->{name});
    $self->stash(current_challenge => scalar $user->current_challenge);

    my @latest_challenges = $self->session('user')->latest_solved_challenges();
    $self->stash(latest_challenges => \@latest_challenges);
    $self->stash(just_solved => scalar $self->flash('just_solved'));

    return 1;
};

get '/logout' => sub {
    my $self = shift;
    $self->session('user')->address(undef);
    $self->session(user => 0);
    $self->redirect_to('/');
};

get '/challenges' => sub {
    my $self = shift;

    my @solved = $self->session('user')->solved_challenges;
    my @unsolved = $self->session('user')->unsolved_challenges;

    $self->render(
        'challenges',
        solved_challenges   => \@solved,
        unsolved_challenges => \@unsolved,
        page_title          => 'Challenges',
    );
};

get '/challenge/:id' => sub {
    my $self = shift;
    my $c    = Intercensor::Challenge->get($self->param('id'));

    if ($c) {
        my $question;
        if (defined($self->stash('current_challenge'))
            and $c == $self->stash('current_challenge'))
        {
            $question = $c->get_question($self->session('user')->{id});
        }

        $self->render(
            'challenge',
            challenge  => $c,
            page_title => $c->name . ' Challenge',
            question   => $question,
            error      => undef,
        );
    }
    else {
        $self->render(
            text   => 'Not Found',
            status => 404
        );
    }
};

post '/challenge/:id/play' => sub {
    my $self = shift;
    my $c    = Intercensor::Challenge->get($self->param('id'));

    if ($c) {

#debug sprintf('User %s starting challenge %s', $self->session('user')->{name}, $self->param('id'));
        my $addr = $self->tx->remote_address;

        $self->session('user')->start_challenge($c);
        $self->redirect_to('/challenge/' . $c->id);
    }
    else {
        $self->render(
            text   => 'No such challenge',
            status => 404
        );
    }
};

post '/challenge/:id/stop' => sub {
    my $self = shift;
    my $c    = Intercensor::Challenge->get($self->param('id'));

    if ($c) {

#debug sprintf('User %s stopping challenge %s', $self->session('user')->{name}, $self->param('id'));
        $self->session('user')->stop_challenge();
        $self->redirect_to('/challenges');
    }
    else {
        $self->render(
            text   => 'No such challenge',
            status => 404
        );
    }
};

post '/challenge/:id/solve' => sub {
    my $self = shift;
    my $c    = Intercensor::Challenge->get($self->param('id'));

    if ($c) {
        my $a = $self->param('answer');

#debug sprintf('User %s solving challenge %s: %s', $self->session('user')->{name}, $self->param('id'), $a);

        if ($c->verify_answer($self->session('user')->{id}, $a)) {
            $self->session('user')->solve_challenge($c);

#debug sprintf('User %s solved challenge %s', $self->session('user')->{name}, $self->param('id'));

            $self->flash(just_solved => $c->name);
            $self->redirect_to('/challenges');
        }
        else {

#debug sprintf('User %s failed to solve challenge %s', $self->session('user')->{name}, $self->param('id'));

            $self->render(
                'challenge',
                challenge  => $c,
                page_title => $c->name . ' Challenge',
                error      => 'Your answer is wrong',
                question   => $c->get_question($self->session('user')->{id}),
            );
        }
    }
    else {
        $self->render(
            text   => 'No such challenge',
            status => 404
        );
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
