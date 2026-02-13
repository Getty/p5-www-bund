package WWW::Bund::CLI::Cmd::BundestagLobbyregister;
our $VERSION = '0.002';
# ABSTRACT: Bundestag Lobbyregister API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund bundestag-lobbyregister list   # List registered lobbyists

=head1 DESCRIPTION

CLI commands for Bundestag Lobbyregister API (lobby registry). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'bundestag_lobbyregister' }

1;
