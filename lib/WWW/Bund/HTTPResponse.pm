package WWW::Bund::HTTPResponse;
our $VERSION = '0.002';
# ABSTRACT: Transport-independent HTTP response object

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::HTTPResponse;

    my $response = WWW::Bund::HTTPResponse->new(
        status       => 200,
        content      => $decoded_body,
        content_type => 'application/json',
    );

=head1 DESCRIPTION

Simple immutable HTTP response object returned by L<WWW::Bund::Role::IO>
implementations. Contains decoded content (not raw bytes).

=cut

has status => (is => 'ro', required => 1);

=attr status

HTTP status code (200, 404, etc.). Required.

=cut

has content => (is => 'ro', default => '');

=attr content

Response body as Perl character string (already decoded). Defaults to empty string.

=cut

has content_type => (is => 'ro', default => '');

=attr content_type

Content-Type header value. Defaults to empty string.

=cut

1;
