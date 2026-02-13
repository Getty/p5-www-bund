package WWW::Bund::Response::JSON;
our $VERSION = '0.002';
# ABSTRACT: JSON response — parses content to Perl data structure

use Moo;
use JSON::MaybeXS qw(decode_json);
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::Response::JSON;

    my $response = WWW::Bund::Response::JSON->new(
        content      => '{"result": "ok"}',
        content_type => 'application/json',
    );

    my $data = $response->data;  # { result => 'ok' }

=head1 DESCRIPTION

Parses JSON response content into Perl data structures (HashRef or ArrayRef).

Uses L<JSON::MaybeXS> for parsing, which selects the fastest available JSON
module (Cpanel::JSON::XS, JSON::XS, or JSON::PP).

Returns C<undef> if content is empty.

=cut

has data => (is => 'lazy');

=attr data

Parsed JSON data (HashRef, ArrayRef, or undef). Lazy-built from C<content>.

=cut

sub _build_data {
    my ($self) = @_;
    return undef unless defined $self->content && length $self->content;
    return decode_json($self->content);
}

with 'WWW::Bund::Role::Response';

1;
