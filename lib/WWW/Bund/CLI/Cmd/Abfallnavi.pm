package WWW::Bund::CLI::Cmd::Abfallnavi;
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'abfallnavi' }

1;

=head1 NAME

WWW::Bund::CLI::Cmd::Abfallnavi - Waste collection schedule command

=head1 SYNOPSIS

  bund abfallnavi orte aachen
  bund abfallnavi fraktionen aachen

=head1 DESCRIPTION

Command interface for Abfallnavi API (waste collection schedules).

Note: Requires region parameter in base_url.

=head1 SEE ALSO

L<WWW::Bund::CLI>, L<WWW::Bund::CLI::Role::APICommand>

=cut
