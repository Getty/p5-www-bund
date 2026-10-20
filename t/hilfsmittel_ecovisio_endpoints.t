use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use WWW::Bund::Registry;

# Regression guard for endpoint-data drift fixed for the hilfsmittel and
# eco_visio APIs (see karr k3). Offline: only inspects share/endpoints.yml.

my $share = File::Spec->catdir($FindBin::Bin, '..', 'share');
my $reg = WWW::Bund::Registry->new(
    registry_file  => File::Spec->catfile($share, 'registry.yml'),
    endpoints_file => File::Spec->catfile($share, 'endpoints.yml'),
);

# hilfsmittel_produkte: the filter param must be UntergruppeId, not the old
# UnterruppeId typo (matches the hilfsmittel_untergruppe entity / OpenAPI spec).
{
    my $ep = $reg->endpoint('hilfsmittel_produkte');
    my %qp = map { $_ => 1 } @{ $ep->{query_params} || [] };
    ok($qp{UntergruppeId},  'hilfsmittel_produkte has UntergruppeId query param');
    ok(!$qp{UnterruppeId},  'hilfsmittel_produkte no longer carries the UnterruppeId typo');
    ok($qp{ProduktgruppeId} && $qp{ProduktartId},
        'hilfsmittel_produkte keeps its sibling filter params');
}

# eco_visio_data: idOrganisme is a documented required query param and was
# missing from the endpoint definition.
{
    my $ep = $reg->endpoint('eco_visio_data');
    my %qp = map { $_ => 1 } @{ $ep->{query_params} || [] };
    ok($qp{idOrganisme}, 'eco_visio_data has idOrganisme query param');
    ok($qp{flowIds} && $qp{interval},
        'eco_visio_data keeps its flowIds/interval params');
}

done_testing;
