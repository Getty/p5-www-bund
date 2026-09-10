package WWW::Bund::CLI::Cmd::Ladestationen;
our $VERSION = '0.003';
# ABSTRACT: Ladestationen (Ladesaeulenregister) API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund ladestationen query                       # All charging stations as GeoJSON
    bund ladestationen query --where "bundesland='Bayern'"
    bund ladestationen query --resultRecordCount 100 --resultOffset 0

=head1 DESCRIPTION

CLI command for the Ladestationen API (Ladesaeulenregister, the German charging
station registry run by the Bundesnetzagentur). Uses
L<WWW::Bund::CLI::Role::APICommand>.

The upstream source is an ArcGIS FeatureServer C<query> layer. The endpoint sends
C<where=1=1>, C<outFields=*> and C<f=geojson> by default, so a bare
C<bund ladestationen query> returns the full GeoJSON FeatureCollection; a bare
request without these would return the ArcGIS HTML query form instead. Override
any of them, or add C<resultRecordCount>/C<resultOffset> for paging, via
C<--name value>.

=head2 Authentication (token)

The registry layer became token-gated in 2026. Authentication is optional here:
without a token the request is still sent (so a live call distinguishes a
url-only problem from a genuinely gated layer), and when a token is available it
is injected as the ArcGIS C<?token=> query parameter.

To provide a token, set the environment variable:

    export LADESTATIONEN_TOKEN=<your-arcgis-token>
    bund ladestationen query

or pass it explicitly for one call:

    bund ladestationen query --token <your-arcgis-token>

B<Obtaining a token.> The layer lives on ArcGIS Online under
C<services6.arcgis.com/6jU7RmJig2Wwo1b0> (item "Ladesaeulenregister"). ArcGIS
tokens are issued by the ArcGIS token service, e.g.

    curl -s 'https://www.arcgis.com/sharing/rest/generateToken' \
        --data-urlencode 'username=USER' \
        --data-urlencode 'password=PASS' \
        --data-urlencode 'referer=https://www.arcgis.com' \
        --data-urlencode 'f=json'

which returns a JSON C<token> field. Use the credentials tied to the account that
has been granted access to the Ladesaeulenregister layer (obtained via the
Bundesnetzagentur / bund.dev registration for this dataset). The token from
C<generateToken> is short-lived; regenerate it when it expires.

This has to be verified against the live service, which offline tests cannot do.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'ladestationen' }

1;
