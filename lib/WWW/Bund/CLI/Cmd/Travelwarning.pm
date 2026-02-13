package WWW::Bund::CLI::Cmd::Travelwarning;

# ABSTRACT: Travelwarning (Reisewarnungen) API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund travelwarning list              # List all warnings
    bund travelwarning country CODE      # Warning for country

=head1 DESCRIPTION

CLI commands for Travel Warning API (Reisewarnungen - foreign travel advisories). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'travelwarning' }

1;
