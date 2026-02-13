package WWW::Bund::Response::Raw;
our $VERSION = '0.002';
# ABSTRACT: Raw response — returns content as-is

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::Response::Raw;

    my $response = WWW::Bund::Response::Raw->new(
        content      => 'plain text response',
        content_type => 'text/plain',
    );

    my $data = $response->data;  # 'plain text response'

=head1 DESCRIPTION

Pass-through response parser for non-JSON, non-XML responses. Returns content
as-is without parsing.

Used as fallback when content type is not recognized.

=cut

sub data { $_[0]->content }

=method data

Returns C<content> unchanged.

=cut

with 'WWW::Bund::Role::Response';

1;
