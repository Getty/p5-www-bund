package WWW::Bund::Role::IO;

# ABSTRACT: Interface role for pluggable HTTP backends

use Moo::Role;

=head1 SYNOPSIS

    package My::HTTP::Backend;
    use Moo;
    with 'WWW::Bund::Role::IO';

    sub call {
        my ($self, $request) = @_;
        # Execute HTTP request
        # Return WWW::Bund::HTTPResponse
    }

=head1 DESCRIPTION

Role defining the interface for HTTP backend implementations. Allows plugging
in alternative HTTP clients (async, mocked, etc.) by implementing the C<call>
method.

The default implementation is L<WWW::Bund::LWPIO> using L<LWP::UserAgent>.

=head1 REQUIRED METHODS

=head2 call

    my $response = $io->call($request);

Execute an HTTP request. Takes L<WWW::Bund::HTTPRequest>, returns
L<WWW::Bund::HTTPResponse>.

=cut

requires 'call';

1;
