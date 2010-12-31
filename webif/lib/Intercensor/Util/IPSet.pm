package Intercensor::Util::IPSet;
use Modern::Perl;
use IPC::System::Simple qw(capture run);
use Sub::Exporter -setup =>
  {exports => [qw(find_ipset add_to_ipset delete_from_ipset)]};

# Setting $SIG{CHLD} here is a workaround for
# https://rt.cpan.org/Public/Bug/Display.html?id=46684 in IPC::System::Simple

sub find_ipset {
    my ($addr) = @_;
    local $SIG{CHLD} = 'DEFAULT';
    my $ipsets = capture('sudo', 'ipset', '-S');
    my ($set) = ($ipsets =~ /^-A (\w+) \Q$addr\E$/gms);
    return $set;
}

sub add_to_ipset {
    my ($set, $addr) = @_;
    local $SIG{CHLD} = 'DEFAULT';
    run 'sudo', 'ipset', '-A', $set, $addr;
}

sub delete_from_ipset {
    my ($set, $addr) = @_;
    local $SIG{CHLD} = 'DEFAULT';
    run 'sudo', 'ipset', '-D', $set, $addr;
}

1;
