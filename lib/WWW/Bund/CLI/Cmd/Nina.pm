package WWW::Bund::CLI::Cmd::Nina;
our $VERSION = '0.002';
# ABSTRACT: NINA Warn-App API commands

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund nina                          # Show help
    bund nina dashboard ARS            # Warnings by region
    bund nina warning IDENTIFIER       # Specific warning
    bund nina mapdata-katwarn          # KATWARN map data
    bund nina mapdata-mowas            # MOWAS map data
    bund nina version                  # API version

=head1 DESCRIPTION

CLI commands for NINA (Notfall-Informations- und Nachrichten-App) disaster
warnings and civil protection alerts. Uses L<WWW::Bund::CLI::Role::APICommand>.

See L<WWW::Bund::API::NINA> for library interface.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'nina' }

1;
