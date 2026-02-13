package WWW::Bund::CLI::Cmd::Bundesrat;

# ABSTRACT: Bundesrat API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund bundesrat sessions        # List sessions
    bund bundesrat documents       # List documents

=head1 DESCRIPTION

CLI commands for Bundesrat API (German Federal Council data). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'bundesrat' }

1;
