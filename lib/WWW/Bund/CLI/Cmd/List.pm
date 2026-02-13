package WWW::Bund::CLI::Cmd::List;

# ABSTRACT: List all available APIs

use Moo;
use MooX::Cmd;
use MooX::Options;

=head1 SYNOPSIS

    bund list
    bund list --output json

=head1 DESCRIPTION

CLI command for listing all registered APIs. Displays ID, title, auth type,
and tags in table format (or JSON/YAML).

See L<WWW::Bund::CLI>.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    my $main = $chain->[0];
    $main->cmd_list();
}

=method execute

Delegate to L<WWW::Bund::CLI/cmd_list>.

=cut

1;
