use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use WWW::Bund::CLI;
use WWW::Bund::Registry;
use WWW::Bund::CLI::Strings;
use WWW::Bund::CLI::Formatter;

# Offline regression test for required-query-param validation in cmd_call.
#
# bundeshaushalt_budget_data needs year+account or the live API answers HTTP 400.
# The endpoint opts in via a `required:` list; cmd_call must reject a call that
# omits a required param BEFORE touching the network, with a usage hint.
#
# FakeBund carries the real registry (so endpoint data, incl. `required`, is
# real) but records call() invocations instead of doing IO -- so we can assert
# no HTTP call is attempted, entirely offline.
{
    package FakeBund;
    use Moo;
    has registry => (is => 'ro', required => 1);
    has calls    => (is => 'ro', default  => sub { [] });
    sub call {
        my ($self, @args) = @_;
        push @{$self->calls}, \@args;
        return { ok => 1 };
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

# Run cmd_call, capturing STDERR (warn) and STDOUT (print) so the test output
# stays clean and we can assert on the messages.
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

# 1. Required param missing -> usage error, no HTTP call attempted.
{
    my $bund = FakeBund->new(registry => $registry);
    my $cli  = build_cli($bund);

    my ($rc, $warned) = call_capture($cli, 'bundeshaushalt', 'budget-data', '2021');

    is($rc, 1, 'missing required query param returns rc 1');
    like($warned, qr/Missing argument.*account/,
        'names the missing required param (account)');
    like($warned, qr/Usage: bund bundeshaushalt budget-data <year> <account>/,
        'usage hint lists path + required query params in order');
    is(scalar @{$bund->calls}, 0,
        'no API call attempted when a required param is missing');
}

# 2. All required params present -> call proceeds (validation does not over-fire).
{
    my $bund = FakeBund->new(registry => $registry);
    my $cli  = build_cli($bund);

    my ($rc) = call_capture($cli, 'bundeshaushalt', 'budget-data', '2021', 'expenses');

    is($rc, 0, 'required params present returns rc 0');
    is(scalar @{$bund->calls}, 1, 'API call made when all required params present');
    is($bund->calls->[0][1], 'bundeshaushalt_budget_data',
        'call dispatched to the correct endpoint');
}

# 3. Opt-in: an endpoint WITHOUT `required` still runs even with a query param
#    omitted -- it is the presence of `required`, not query_params, that gates.
{
    my $bund = FakeBund->new(registry => $registry);
    my $cli  = build_cli($bund);

    # tagesschau_search has query_params (searchText) but no `required:` list.
    my ($rc, $warned) = call_capture($cli, 'tagesschau', 'search');

    is($rc, 0, 'endpoint without required runs even with query param omitted');
    unlike($warned, qr/Missing argument/,
        'no missing-argument error for an endpoint without required');
    is(scalar @{$bund->calls}, 1,
        'API call made for endpoint without required');
}

done_testing;
