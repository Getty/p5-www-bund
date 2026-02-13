package WWW::Bund::Role::Response;

# ABSTRACT: Role for typed API response objects

use Moo::Role;

=head1 SYNOPSIS

    package WWW::Bund::Response::MyFormat;
    use Moo;
    with 'WWW::Bund::Role::Response';

    has data => (is => 'lazy');

    sub _build_data {
        my ($self) = @_;
        # Parse $self->content
        return $parsed_data;
    }

=head1 DESCRIPTION

Role for response parser classes. Consumes raw HTTP response content and
provides parsed C<data>.

Implementations:

=over

=item * L<WWW::Bund::Response::JSON> - Parses JSON to Perl data structures

=item * L<WWW::Bund::Response::XML> - Parses XML to HashRef via XML::Twig

=item * L<WWW::Bund::Response::Raw> - Returns content as-is

=back

=cut

has content => (is => 'ro', default => '');

=attr content

Raw response content (character string). Defaults to empty string.

=cut

has content_type => (is => 'ro', default => '');

=attr content_type

Content-Type header value. Defaults to empty string.

=cut

requires 'data';

=head1 REQUIRED ATTRIBUTES

=head2 data

Parsed response data. Must be implemented by consuming classes.

Typically lazy-built from C<content>.

=cut

1;
