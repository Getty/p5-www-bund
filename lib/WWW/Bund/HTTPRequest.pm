package WWW::Bund::HTTPRequest;
our $VERSION = '0.002';
# ABSTRACT: Transport-independent HTTP request object

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::HTTPRequest;

    my $req = WWW::Bund::HTTPRequest->new(
        method  => 'GET',
        url     => 'https://example.com/api',
        headers => { Authorization => 'Bearer TOKEN' },
        content => $json_body,  # optional
    );

=head1 DESCRIPTION

Simple immutable HTTP request object used as input to L<WWW::Bund::Role::IO>
implementations. Transport-independent representation of an HTTP request.

=cut

has method => (is => 'ro', required => 1);

=attr method

HTTP method (GET, POST, etc.). Required.

=cut

has url => (is => 'ro', required => 1);

=attr url

Full URL including scheme, host, path, and query string. Required.

=cut

has headers => (is => 'ro', default => sub { {} });

=attr headers

HashRef of HTTP headers. Defaults to empty HashRef.

=cut

has content => (is => 'ro', predicate => 1);

=attr content

Request body content (for POST, PUT, etc.). Optional.

Use C<has_content> predicate to check if content is set.

=cut

1;
