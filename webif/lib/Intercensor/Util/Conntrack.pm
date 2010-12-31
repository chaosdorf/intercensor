package Intercensor::Util::Conntrack;
use Modern::Perl;
use IPC::System::Simple qw(run);
use Sub::Exporter -setup => {exports => [qw(delete_conntrack_states)]};

sub delete_conntrack_states {
    my ($addr) = @_;

    # conntrack returns 1 even if the arguments are okay, but
    # no flow states have been deleted.
    run([0 .. 1], 'sudo', 'conntrack', '-D', '-s', $addr);
    run([0 .. 1], 'sudo', 'conntrack', '-D', '-d', $addr);
}

1;
