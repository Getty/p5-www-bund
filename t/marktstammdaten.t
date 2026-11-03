#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use WWW::Bund::CLI;
use WWW::Bund::Registry;
use WWW::Bund::CLI::Strings;
use WWW::Bund::CLI::Formatter;

# Offline regression test for the Marktstammdatenregister data endpoints.
#
# karr k6 claimed these endpoints (strom_erzeugung etc.) need their filter
# params sent as a POST body. Verified LIVE against the real API, that premise
# is WRONG:
#   * GET .../GetErweiterteOeffentlicheEinheitStromerzeugung?...&filter=  -> HTTP
#     200 with real JSON ("Total": 9429030). Passing filter=Energieträger~eq~
#     '2497' over GET narrows it (wind only, "Total": 43477) -- filtering works.
#   * A POST to the same action is rejected ("public action method ... was not
#     found"). Switching method to `post` would BREAK these endpoints.
#
# So share/endpoints.yml is already correct: method `get`, `filter` among the
# query_params. This test locks that wiring in so a future "switch to POST" or
# "drop the filter param" regression fails loudly and offline.
#
# FakeBund carries the real registry (so endpoint data is real) but records
# call() invocations instead of doing IO -- no network here (pattern from
# t/cli_required.t).
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

sub build_cli {
    my $bund = shift;
    return WWW::Bund::CLI->new(
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
}

# Run cmd_call while swallowing STDOUT (formatter output) and warnings, so the
# test output stays clean and no network IO ever runs.
sub call_capture {
    my ($cli, @args) = @_;
    my ($warned, $printed) = ('', '');
    my $rc;
    {
        local $SIG{__WARN__} = sub { $warned .= $_[0] };
        open my $fh, '>', \$printed or die $!;
        local *STDOUT = $fh;
        $rc = $cli->cmd_call(@args);
    }
    return ($rc, $warned, $printed);
}

# The four Marktstammdaten "data" endpoints (the ones that take query params).
my @data_endpoints = qw(
    marktstammdaten_strom_erzeugung
    marktstammdaten_strom_verbrauch
    marktstammdaten_gas_erzeugung
    marktstammdaten_gas_verbrauch
);

# 1. Endpoint definitions: GET + a `filter` query param, for all four.
#    Fails if someone flips the method to `post` or removes `filter`.
for my $name (@data_endpoints) {
    my $ep = $registry->endpoint($name);

    is(lc($ep->{method}), 'get',
        "$name is a GET endpoint (a POST is rejected by the live API)");

    my @qp = @{$ep->{query_params} // []};
    ok((grep { $_ eq 'filter' } @qp),
        "$name lists `filter` among its query_params");

    # filter must stay reachable as a trailing positional, so the CLI can pass
    # it. Record its index for the mapping assertion below.
    my ($filter_idx) = grep { $qp[$_] eq 'filter' } 0 .. $#qp;
    ok(defined $filter_idx, "$name has a positional slot for `filter`");
}

# 2. cmd_call maps a positional `filter` value into params{filter} and passes it
#    through to the call engine (offline). strom_erzeugung is representative;
#    its query_params order is [sort, page, pageSize, filter].
{
    my $bund = FakeBund->new(registry => $registry);
    my $cli  = build_cli($bund);

    my $ep = $registry->endpoint('marktstammdaten_strom_erzeugung');
    my @qp = @{$ep->{query_params}};

    # Build positionals so the filter value lands in the filter slot. Earlier
    # slots (sort/page/pageSize) get harmless placeholders.
    my $filter_value = "Energieträger~eq~'2497'";
    my @positional;
    for my $i (0 .. $#qp) {
        $positional[$i] = $qp[$i] eq 'filter' ? $filter_value
                        : $qp[$i] eq 'page'    ? '1'
                        : $qp[$i] eq 'pageSize'? '5'
                        :                        '';
    }

    my ($rc, $warned) = call_capture(
        $cli, 'marktstammdaten', 'strom-erzeugung', @positional,
    );

    is($rc, 0, 'cmd_call succeeds for a data endpoint call');
    unlike($warned, qr/Missing argument/,
        'no missing-argument error for the data endpoint');

    is(scalar @{$bund->calls}, 1, 'exactly one API call dispatched (offline)');

    my ($call) = @{$bund->calls};
    # FakeBund->call was invoked as ($api, $endpoint_name, params => \%params)
    is($call->[0], 'marktstammdaten', 'call dispatched for the marktstammdaten API');
    is($call->[1], 'marktstammdaten_strom_erzeugung',
        'call dispatched to the strom_erzeugung endpoint');

    my %opts = @{$call}[2 .. $#$call];
    my $params = $opts{params};
    is(ref $params, 'HASH', 'params passed as a hashref');
    is($params->{filter}, $filter_value,
        'positional filter value is mapped into params{filter} and passed through');

    # Guard the ordering too: the earlier positionals landed on the right keys.
    is($params->{page},     '1', 'page positional mapped to params{page}');
    is($params->{pageSize}, '5', 'pageSize positional mapped to params{pageSize}');
}

# 3. Cross-check: if `filter` were dropped from query_params, a trailing
#    positional filter value would have nowhere to map and never reach the call.
#    Confirm today it DOES reach it for every data endpoint (not just the one
#    exercised above), so all four stay wired.
for my $name (@data_endpoints) {
    my $bund = FakeBund->new(registry => $registry);
    my $cli  = build_cli($bund);

    my $ep = $registry->endpoint($name);
    my @qp = @{$ep->{query_params}};
    my $action = $cli->_endpoint_to_action('marktstammdaten', $name);

    my $filter_value = "Bundesland~eq~'1402'";
    my @positional;
    for my $i (0 .. $#qp) {
        $positional[$i] = $qp[$i] eq 'filter' ? $filter_value : ($qp[$i] eq 'page' ? '1' : '');
    }

    my ($rc) = call_capture($cli, 'marktstammdaten', $action, @positional);
    is($rc, 0, "$name: cmd_call succeeds");

    my %opts = @{$bund->calls->[0]}[2 .. $#{$bund->calls->[0]}];
    is($opts{params}{filter}, $filter_value,
        "$name: trailing positional reaches params{filter}");
}

done_testing;
