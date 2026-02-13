package WWW::Bund::CLI::Cmd::Tagesschau;

# ABSTRACT: Tagesschau API commands

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund tagesschau              # Show help
    bund tagesschau homepage     # Homepage news
    bund tagesschau news         # All news
    bund tagesschau search QUERY # Search news
    bund tagesschau channels     # List channels

=head1 DESCRIPTION

CLI commands for Tagesschau API (news from Germany's main public broadcasting
news service). Uses L<WWW::Bund::CLI::Role::APICommand>.

See L<WWW::Bund::API::Tagesschau> for library interface.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'tagesschau' }

1;
