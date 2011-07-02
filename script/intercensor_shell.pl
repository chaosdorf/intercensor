#!/usr/bin/env perl
use strict;
use warnings;

# From http://www.solarant.org/shell-for-catalyst/

use Devel::REPL;
my $repl = Devel::REPL->new();

$repl->load_plugin($_) for qw(
    Colors
    Completion
    CompletionDriver::Globals
    CompletionDriver::INC
    CompletionDriver::Keywords
    CompletionDriver::LexEnv
    CompletionDriver::Methods
    DataPrinter
    History
    LexEnv
    Interrupt
    MultiLine::PPI
    OutputCache
    Timing
);

$repl->lexical_environment->do(<<'CODEZ');
use FindBin;
use lib "$FindBin::Bin/../lib";
use Intercensor::Model::DB;

my $modelconfig = Intercensor::Model::DB->config;
my $schema_class = $modelconfig->{schema_class};
my $dsn = $modelconfig->{connect_info}->{dsn};
my $user = $modelconfig->{connect_info}->{user};
my $password = $modelconfig->{connect_info}->{password};

eval "use $schema_class";
my $s = $schema_class->connect($dsn,$user,$password);

CODEZ

$repl->run;
