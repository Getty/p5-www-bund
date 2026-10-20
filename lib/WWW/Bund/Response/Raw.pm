package WWW::Bund::Response::Raw;
our $VERSION = '0.003';
# ABSTRACT: Raw response - returns the decoded content as-is

use Moo;
use Encode ();
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::Response::Raw;

    my $response = WWW::Bund::Response::Raw->new(
        content      => 'plain text response',
        content_type => 'text/plain',
    );

    my $data = $response->data;  # 'plain text response'

=head1 DESCRIPTION

Pass-through response parser for non-JSON, non-XML responses. Returns the
content without parsing it.

The HTTP transport hands the body over as bytes (UTF-8 encoded) - this parser
decodes them, so C<data> is a Perl character string. A body that is not valid
UTF-8 is passed through byte for byte.

Used as fallback when content type is not recognized.

=cut

has data => (is => 'lazy');

=attr data

The content, decoded from UTF-8. Lazy-built from C<content>.

=cut

sub _build_data {
    my ($self) = @_;
    my $content = $self->content;
    return $content unless defined $content && length $content;

    # The transport hands the body over as bytes, the parser decodes them.
    # Content that is already a character string is left alone.
    return $content if utf8::is_utf8($content);

    # A body that is not valid UTF-8 stays as it is - broken bytes are no
    # reason to throw the answer away.
    my $decoded = eval { Encode::decode( 'UTF-8', $content, Encode::FB_CROAK ) };
    return $content unless defined $decoded;
    return $decoded;
}

with 'WWW::Bund::Role::Response';

1;
