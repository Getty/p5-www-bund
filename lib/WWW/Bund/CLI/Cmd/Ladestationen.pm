package WWW::Bund::CLI::Cmd::Ladestationen;

# ABSTRACT: Ladestationen (Ladesaeulenregister) API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund ladestationen list   # List charging stations

=head1 DESCRIPTION

CLI commands for Ladestationen API (electric vehicle charging station registry). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'ladestationen' }

1;
