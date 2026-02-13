package WWW::Bund::CLI::Cmd::Hilfsmittel;

# ABSTRACT: Hilfsmittel (GKV Hilfsmittelverzeichnis) API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund hilfsmittel search QUERY   # Search medical aids
    bund hilfsmittel categories     # List categories

=head1 DESCRIPTION

CLI commands for Hilfsmittel API (GKV medical aids directory). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'hilfsmittel' }

1;
