#!/usr/bin/env perl
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

# hilfsmittel_produkte: the API ignores every filter parameter - fetched with
# UntergruppeId, with ProduktartId and without parameters at all, every
# variant answers with the byte-identical full list of 66025 products. The
# OpenAPI spec documents /Produkt without parameters, so the endpoint carries
# none and the CLI offers no positional argument for them.
{
    my $ep = $reg->endpoint('hilfsmittel_produkte');
    is_deeply($ep->{query_params} // [], [],
        'hilfsmittel_produkte carries no filter parameter');
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
