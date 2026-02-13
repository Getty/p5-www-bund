package WWW::Bund::CLI::Cmd::Autobahn;

# ABSTRACT: Autobahn App API commands

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund autobahn                     # Show help
    bund autobahn roads               # List all Autobahn roads
    bund autobahn roadworks A7        # Roadworks on A7
    bund autobahn webcams A7          # Webcams on A7
    bund autobahn warnings A7         # Warnings on A7
    bund autobahn closures A7         # Closures on A7
    bund autobahn charging-stations A7
    bund autobahn parking-lorries A7

=head1 DESCRIPTION

CLI commands for the Autobahn App API (traffic, roadworks, webcams, warnings,
charging stations). Uses L<WWW::Bund::CLI::Role::APICommand> for dispatch.

See L<WWW::Bund::API::Autobahn> for library interface.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'autobahn' }

1;
