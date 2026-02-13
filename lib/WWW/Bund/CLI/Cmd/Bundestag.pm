package WWW::Bund::CLI::Cmd::Bundestag;
our $VERSION = '0.002';
# ABSTRACT: Bundestag API commands

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund bundestag speaker          # Speaker info
    bund bundestag mdb-index        # List all MdB
    bund bundestag ausschuesse      # List committees

=head1 DESCRIPTION

CLI commands for Bundestag API (German Federal Parliament data). Uses L<WWW::Bund::CLI::Role::APICommand>. See L<WWW::Bund::API::Bundestag>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'bundestag' }

1;
