package WWW::Bund::CLI::Cmd::EcoVisio;

# ABSTRACT: Eco-Visio (Fahrrad-Zähler) API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund eco-visio sites    # List bicycle counter sites
    bund eco-visio data     # Get counter data

=head1 DESCRIPTION

CLI commands for Eco-Visio API (bicycle traffic counter data). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'eco_visio' }

1;
