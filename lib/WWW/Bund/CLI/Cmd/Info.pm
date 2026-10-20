package WWW::Bund::CLI::Cmd::Info;
our $VERSION = '0.003';
# ABSTRACT: Show detailed API information

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0;

=head1 SYNOPSIS

    bund info autobahn
    bund info pegel --output json

=head1 DESCRIPTION

CLI command for displaying detailed information about an API: provider, auth
requirements, documentation URL, rate limits, and list of available endpoints.

See L<WWW::Bund::CLI>.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    my $main = $chain->[0];

    unless (@$args) {
        warn $main->_s('err_usage_info') . "\n";
        exit(1);
    }

    # An empty argument did not survive the argument split of MooX::Cmd, the
    # root CLI encodes it - decode it here, where it is used.
    my $api = $main->_decode_arg( $args->[0] );

    unless ( length $api ) {
        warn $main->_s('err_usage_info') . "\n";
        exit(1);
    }

    $main->cmd_info( $main->_resolve_api($api) );
}

=method execute

Validate arguments and delegate to L<WWW::Bund::CLI/cmd_info>.

=cut

1;
