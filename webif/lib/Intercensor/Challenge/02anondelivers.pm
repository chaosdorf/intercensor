package Intercensor::Challenge::02anondelivers;

use Modern::Perl;
use base qw(Intercensor::Challenge);
use XML::LibXML;
use LWP::Simple;

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
    href="http://www.4chan.org/b/">4chan.org/b</a>. Create a new thread and put
    {{{TOKEN}}} into the body. Give us the URL of the resulting thread.</p>
    <p>(Note that the {{{ }}} are required)</p>';
}

sub get_question {
    my ($self, $user_id) = @_;
    return $self->generate_token($user_id);
}

sub verify_answer {
    my ($self, $user_id, $answer) = @_;

    if ($answer !~ m{^http://boards.4chan.org/b/res}) {
        return undef;
    }

    my $content = get($answer);
    if (!defined $content) {
        return undef;
    }

    my $tree;
    {

        # XML::LibXML likes to spam with warnings.
        local $SIG{__WARN__} = sub { };
        $tree = XML::LibXML->load_html(
            string  => $content,
            recover => 1
        );
    }

    my $post = $tree->findnodes('//blockquote')->[0];

    if (!defined $post) {
        return undef;
    }

    my $text = $post->textContent;

    if ($text =~ /\{{3}(.+?)\}{3}/) {
        my $token = $1;
        return ($token eq $self->generate_token($user_id));
    }
    else {
        return undef;
    }

}

1;
