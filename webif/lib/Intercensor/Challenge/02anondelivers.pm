package Intercensor::Challenge::02anondelivers;

use Modern::Perl;
use base qw(Intercensor::Challenge);

sub id {
    '02anondelivers';
}

sub name {
    'Anon Delivers';
}

sub description {
    '<p>Man the harpoons!<br/>
    We have an encrypted token for you, which we need to deliver to another
    person via the 4chan imageboard.</p>
    <p>Your task is to plant it on <a
    href="http://www.4chan.org/b/">4chan.org/b</a> and give us the URL to the
    resulting thread</p>';
}

sub get_question {
    my ($self, $user_id) = @_;
    return $self->generate_token($user_id);
}

sub verify_answer {
    my ($self, $user_id, $answer) = @_;
    return ($answer eq $self->generate_token($user_id));
}

1;
