package WWW::Bund::CLI::Cmd::Luftqualitaet;
our $VERSION = '0.003';
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'luftqualitaet' }

1;

=head1 NAME

WWW::Bund::CLI::Cmd::Luftqualitaet - Air quality data command

=head1 SYNOPSIS

  bund luftqualitaet components
  bund luftqualitaet measures 2024-01-01 00 2024-01-01 23 DEBW118
  bund luftqualitaet stationsettings

=head1 DESCRIPTION

Command interface for Luftqualität API (Umweltbundesamt).

Provides access to air quality measurements, stations, and metadata.

=head1 SEE ALSO

L<WWW::Bund::CLI>, L<WWW::Bund::CLI::Role::APICommand>

=cut
