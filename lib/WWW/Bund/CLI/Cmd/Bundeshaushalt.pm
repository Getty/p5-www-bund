package WWW::Bund::CLI::Cmd::Bundeshaushalt;

# ABSTRACT: Bundeshaushalt API command

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund bundeshaushalt haushalt   # Federal budget data

=head1 DESCRIPTION

CLI commands for Bundeshaushalt API (German federal budget). Uses L<WWW::Bund::CLI::Role::APICommand>.

=cut

with 'WWW::Bund::CLI::Role::APICommand';

sub api_id { 'bundeshaushalt' }

1;
