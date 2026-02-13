package WWW::Bund::CLI::Cmd::Pegel;
our $VERSION = '0.002';
# ABSTRACT: Pegel Online API commands

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund pegel                          # Show help
    bund pegel stations                 # List all gauging stations
    bund pegel station UUID             # Get station details
    bund pegel waters                   # List all waters
    bund pegel timeseries STATION TS    # Get timeseries metadata
    bund pegel measurements STATION TS  # Get measurements

=head1 DESCRIPTION

CLI commands for Pegel Online API (water level gauges and measurements for
German rivers and waterways). Uses L<WWW::Bund::CLI::Role::APICommand>.

Alias: C<pegel> maps to C<pegel_online>.

See L<WWW::Bund::API::PegelOnline> for library interface.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'pegel_online' }

1;
