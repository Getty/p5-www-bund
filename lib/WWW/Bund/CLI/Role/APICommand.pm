package WWW::Bund::CLI::Role::APICommand;

# ABSTRACT: Shared role for API command dispatch

use Moo::Role;

=head1 SYNOPSIS

    package WWW::Bund::CLI::Cmd::MyAPI;
    use Moo;
    use MooX::Cmd;
    use MooX::Options protect_argv => 0;

    with 'WWW::Bund::CLI::Role::APICommand';

    sub api_id { 'my_api' }

    1;

=head1 DESCRIPTION

Shared role for API-specific CLI command classes. Provides generic C<execute>
method that dispatches to the root CLI's C<cmd_call> or C<cmd_api_help>.

Consuming classes only need to implement C<api_id> method to return the API
identifier. This keeps API command classes minimal (typically 10 lines).

=head2 Execution Flow

=over

=item 1. If no args: show API help via C<cmd_api_help>

=item 2. Otherwise: extract action from first arg, call C<cmd_call>

=item 3. Exit with return code if call fails

=back

=cut

requires 'api_id';

=head1 REQUIRED METHODS

=head2 api_id

    sub api_id { 'autobahn' }

Return the API identifier string used for endpoint lookup.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    my $main = $chain->[0];
    my $api = $self->api_id;

    if (!@$args) {
        $main->cmd_api_help($api);
        return;
    }

    my @call_args = @$args;
    my $action = shift @call_args;

    my $rc = $main->cmd_call($api, $action, @call_args);
    exit($rc) if $rc;
}

=method execute

Generic command execution. Handles both help display and API call dispatch.

=cut

1;
