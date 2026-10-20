package WWW::Bund::CLI::Cmd::EcoVisio;
our $VERSION = '0.003';
# ABSTRACT: Eco-Visio (Fahrrad-Zaehler) API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund eco-visio sites    # List bicycle counter sites
    bund eco-visio data     # Get counter data

=head1 DESCRIPTION

CLI commands for Eco-Visio API (bicycle traffic counter data). Uses L<WWW::Bund::CLI::Role::APICommand>.

The API delivers nothing that can be rendered at the moment (measured on
2026-10-20): the counters answer with 404 Not Found for every published id,
the data with 400 Bad Request, so the CLI shows the raw answer of the API.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'eco_visio' }

1;
