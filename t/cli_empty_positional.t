use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use WWW::Bund::CLI;
use WWW::Bund::Registry;
use WWW::Bund::CLI::Strings;
use WWW::Bund::CLI::Formatter;

# Offline regression test for empty positional arguments.
#
# MooX::Cmd splits @ARGV with shellwords(join ' ', map { quotemeta } @ARGV).
# An empty argument does not survive that round trip: it is dropped and the
# following arguments shift to the wrong parameters. So
#
#   bund marktstammdaten strom-erzeugung "" 1 5 ""
#
# reached the API as sort=1&page=5 instead of sort=&page=1&pageSize=5&filter=.
# The marktstammdaten data API needs the filter parameter present even when it
# is empty, so the unfiltered call was impossible via the CLI.
#
# This test drives the real argument path (WWW::Bund::CLI->new_with_cmd with a
# local @ARGV), not cmd_call: cmd_call was never the broken part.
#
# FakeBund carries the real registry (so the endpoint data is real) but records
# call() invocations instead of doing IO -- no network here (pattern from
# t/marktstammdaten.t).
{
    package FakeBund;
    use Moo;
    has registry => (is => 'ro', required => 1);
    has calls    => (is => 'ro', default  => sub { [] });
    sub call {
        my ($self, @args) = @_;
        push @{$self->calls}, \@args;
        # Shape the response like the real API so the template renders cleanly.
        return { Data => [], Total => 0 };
    }
}

my $share = File::Spec->catdir($FindBin::Bin, '..', 'share');

my $registry = WWW::Bund::Registry->new(
    registry_file  => File::Spec->catfile($share, 'registry.yml'),
    endpoints_file => File::Spec->catfile($share, 'endpoints.yml'),
);

# Run the command distribution the way bin/bund does: with a local @ARGV and
# a fake call engine. The command role calls exit() on an error, so the exit
# is trapped - a failed call has to show up as a test failure, not as a
# crashed test process.
sub run_cli {
    my ($bund, @argv) = @_;

    my ($printed, $warned, $exit_code, $error);
    {
        local @ARGV = @argv;
        no warnings 'once';
        local *CORE::GLOBAL::exit = sub { $exit_code = $_[0]; die "CLI called exit\n" };
        open my $fh, '>', \$printed or die $!;
        local *STDOUT = $fh;
        local $SIG{__WARN__} = sub { $warned .= $_[0] };
        eval {
            WWW::Bund::CLI->new_with_cmd(
                bund      => $bund,
                lang      => 'en',
                strings   => WWW::Bund::CLI::Strings->new(
                    lang        => 'en',
                    strings_dir => File::Spec->catdir($share, 'strings'),
                ),
                formatter => WWW::Bund::CLI::Formatter->new(
                    templates_dir => File::Spec->catdir($share, 'templates'),
                    strings_dir   => File::Spec->catdir($share, 'strings'),
                    lang          => 'en',
                ),
            );
            1;
        } or $error = $@;
    }

    return {
        printed   => $printed,
        warned    => $warned,
        exit_code => $exit_code,
        error     => $error,
    };
}

sub call_params {
    my ($bund) = @_;
    my ($call) = @{$bund->calls};
    return unless $call;
    my %opts = @{$call}[ 2 .. $#$call ];
    return $opts{params};
}

# 1. An empty positional argument keeps its slot: the four positionals map to
#    the four query parameters of the endpoint (sort, page, pageSize, filter).
{
    my $bund = FakeBund->new(registry => $registry);
    my $run = run_cli($bund, 'marktstammdaten', 'strom-erzeugung', '', '1', '5', '');

    is($run->{error}, undef, 'the CLI call did not die');
    is($run->{exit_code}, undef, 'the CLI did not exit');
    unlike($run->{warned}, qr/Missing argument/, 'no missing-argument error');

    is(scalar @{$bund->calls}, 1, 'exactly one API call dispatched (offline)');

    my $params = call_params($bund);
    ok(defined $params, 'the call carried parameters');
    is($params->{sort},     '', 'the empty first positional lands on sort');
    is($params->{page},     '1', 'page positional mapped to params{page}');
    is($params->{pageSize}, '5', 'pageSize positional mapped to params{pageSize}');
    is($params->{filter},   '', 'the empty last positional lands on filter');
}

# 2. The normal case must not move: two positionals are still sort and page.
{
    my $bund = FakeBund->new(registry => $registry);
    my $run = run_cli($bund, 'marktstammdaten', 'strom-erzeugung', '1', '5');

    is($run->{error}, undef, 'the CLI call did not die');
    is(scalar @{$bund->calls}, 1, 'exactly one API call dispatched (offline)');

    my $params = call_params($bund);
    is($params->{sort}, '1', 'sort positional mapped to params{sort}');
    is($params->{page}, '5', 'page positional mapped to params{page}');
    ok(!exists $params->{pageSize}, 'no pageSize invented');
    ok(!exists $params->{filter},   'no filter invented');
}

# 3. Counter check on another API: the path parameter still lands where it
#    belongs and nothing is shifted.
{
    my $bund = FakeBund->new(registry => $registry);
    my $run = run_cli($bund, 'autobahn', 'roadworks', 'A7');

    is($run->{error}, undef, 'the CLI call did not die');
    is(scalar @{$bund->calls}, 1, 'exactly one API call dispatched (offline)');

    my ($call) = @{$bund->calls};
    is($call->[1], 'autobahn_roadworks', 'call dispatched to the roadworks endpoint');

    my $params = call_params($bund);
    is($params->{roadId}, 'A7', 'the path parameter landed on roadId');
}

# 4. The info command keeps its usage error: an empty API name is still a
#    missing argument, the encoding token must not show up in the message.
{
    my $bund = FakeBund->new(registry => $registry);
    my $run = run_cli($bund, 'info', '');

    is($run->{exit_code}, 1, 'the info command exits with 1 for an empty API name');
    like($run->{warned}, qr/Usage: bund info/, 'the usage error is shown');
    unlike($run->{warned}, qr/__www_bund_arg_/, 'no encoding token in the message');
}

done_testing;
