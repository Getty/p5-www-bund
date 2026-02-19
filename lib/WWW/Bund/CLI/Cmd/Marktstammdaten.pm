package WWW::Bund::CLI::Cmd::Marktstammdaten;
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'marktstammdaten' }

1;

=head1 NAME

WWW::Bund::CLI::Cmd::Marktstammdaten - Energy market master data command

=head1 SYNOPSIS

  bund marktstammdaten strom-erzeugung
  bund marktstammdaten gas-verbrauch

=head1 DESCRIPTION

Command interface for Marktstammdatenregister API (Bundesnetzagentur).

=head1 SEE ALSO

L<WWW::Bund::CLI>, L<WWW::Bund::CLI::Role::APICommand>

=cut
