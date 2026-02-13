package WWW::Bund::CLI::Cmd::Dwd;

# ABSTRACT: DWD Weather API commands

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund dwd warnings-nowcast        # Current warnings
    bund dwd municipality-warnings   # Warnings by municipality
    bund dwd coast-warnings          # Coastal warnings

=head1 DESCRIPTION

CLI commands for DWD (Deutscher Wetterdienst) weather warnings. Uses L<WWW::Bund::CLI::Role::APICommand>. See L<WWW::Bund::API::DWD>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'dwd' }

1.
