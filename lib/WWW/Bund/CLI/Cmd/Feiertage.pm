package WWW::Bund::CLI::Cmd::Feiertage;
our $VERSION = '0.002';
# ABSTRACT: Feiertage API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund feiertage list YEAR STATE   # List public holidays

=head1 DESCRIPTION

CLI commands for Feiertage API (German public holidays by state and year). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'feiertage' }

1;
