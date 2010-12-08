package Intercensor::Challenge::01recordbreaker;

use Modern::Perl;
use base qw(Intercensor::Challenge);
use XML::Feed;
use URI;

sub id {
    '01recordbreaker';
}

sub name {
    'Record Breaker';
}

sub description {
    '<p>Let\'s start with something simple. "Fefe\'s Blog" is a site well-known
    for spreading conspiracy theories and general non-conforming information.
    Because of this, access to it is prohibited</p>
    <p>Your task is to retrieve the latest blog headline and then give it to
    us.</p>';
}

sub verify_answer {
    my ($self, $user_id, $answer) = @_;
    my $f = XML::Feed->parse(URI->new('http://blog.fefe.de/rss.xml'))
      or die XML::Feed->errstr;
    my $headline = [ $f->entries() ]->[0]->title;

    $headline =~ s/\W+//g;
    $answer =~ s/\W+//g;

    return ($headline eq $answer);
}

1;
