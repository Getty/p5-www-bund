package WWW::Bund::CLI::Cmd::Smard;
our $VERSION = '0.002';
# ABSTRACT: SMARD (Strommarktdaten) API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund smard chart-data       # Chart data
    bund smard filter-copy      # Filter options
    bund smard indices          # Available indices

=head1 DESCRIPTION

CLI commands for SMARD API (Strommarktdaten - electricity market data). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'smard' }

1;
