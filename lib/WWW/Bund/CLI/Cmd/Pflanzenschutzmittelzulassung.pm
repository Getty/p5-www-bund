package WWW::Bund::CLI::Cmd::Pflanzenschutzmittelzulassung;
our $VERSION = '0.003';
use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'pflanzenschutzmittelzulassung' }

1;

=head1 NAME

WWW::Bund::CLI::Cmd::Pflanzenschutzmittelzulassung - Plant protection products command

=head1 SYNOPSIS

  bund pflanzenschutzmittelzulassung mittel
  bund pflanzenschutzmittelzulassung wirkstoff

=head1 DESCRIPTION

Command interface for Pflanzenschutzmittelzulassungen API (BVL).

=head1 SEE ALSO

L<WWW::Bund::CLI>, L<WWW::Bund::CLI::Role::APICommand>

=cut
