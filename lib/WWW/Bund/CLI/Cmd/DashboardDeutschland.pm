package WWW::Bund::CLI::Cmd::DashboardDeutschland;
our $VERSION = '0.002';
# ABSTRACT: Dashboard Deutschland API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund dashboard-deutschland indicators   # List indicators
    bund dashboard-deutschland data         # Get indicator data

=head1 DESCRIPTION

CLI commands for Dashboard Deutschland API (government statistics dashboard). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'dashboard_deutschland' }

1;
