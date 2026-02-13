package WWW::Bund::LWPIO;
our $VERSION = '0.002';
# ABSTRACT: Synchronous HTTP backend using LWP::UserAgent

use Moo;
use LWP::UserAgent;
use HTTP::Request;
use WWW::Bund::HTTPResponse;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::LWPIO;

    my $io = WWW::Bund::LWPIO->new(timeout => 30);
    my $response = $io->call($request);

=head1 DESCRIPTION

Default HTTP backend for L<WWW::Bund>. Uses L<LWP::UserAgent> for synchronous
HTTP requests. Implements L<WWW::Bund::Role::IO>.

=cut

with 'WWW::Bund::Role::IO';

has timeout => (is => 'ro', default => 30);

=attr timeout

HTTP request timeout in seconds. Defaults to C<30>.

=cut

has ua => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        LWP::UserAgent->new(
            agent   => 'WWW-Bund/' . ($WWW::Bund::VERSION // 'dev'),
            timeout => $self->timeout,
        );
    },
);

=attr ua

L<LWP::UserAgent> instance for making HTTP requests.

=cut

sub call {
    my ($self, $req) = @_;

    my $http_req = HTTP::Request->new($req->method => $req->url);

    my $headers = $req->headers;
    for my $header (keys %$headers) {
        $http_req->header($header => $headers->{$header});
    }

    $http_req->content($req->content) if $req->has_content;

    my $response = $self->ua->request($http_req);

    return WWW::Bund::HTTPResponse->new(
        status       => $response->code,
        content      => $response->decoded_content // '',
        content_type => $response->header('Content-Type') // '',
    );
}

=method call

    my $response = $io->call($request);

Execute HTTP request. Takes L<WWW::Bund::HTTPRequest>, returns
L<WWW::Bund::HTTPResponse> with decoded content.

=cut

1;
