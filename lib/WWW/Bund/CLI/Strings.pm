package WWW::Bund::CLI::Strings;

# ABSTRACT: Localized string provider for bund CLI

use Moo;
use YAML::PP qw(LoadFile);
use Carp qw(croak);
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::CLI::Strings;

    my $strings = WWW::Bund::CLI::Strings->new(
        lang        => 'en',
        strings_dir => 'share/strings',
    );

    my $msg = $strings->get('title');
    my $err = $strings->get('err_unknown_api', 'my_api');

=head1 DESCRIPTION

Loads and provides access to localized CLI strings from YAML files. Supports
7 languages: de, en, fr, es, it, nl, pl.

String files are located at C<{strings_dir}/{lang}.yml> and contain key-value
pairs. Values can include C<sprintf>-style placeholders for dynamic content.

If a key is not found, the key itself is returned.

=cut

has lang => (is => 'ro', default => 'de');

=attr lang

Language code (de, en, fr, es, it, nl, pl). Defaults to C<de>.

=cut

has strings_dir => (is => 'ro', required => 1);

=attr strings_dir

Directory containing string YAML files (e.g., C<de.yml>, C<en.yml>). Required.

=cut

has _strings => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        my $file = "$self->{strings_dir}/$self->{lang}.yml";
        croak "String file not found: $file" unless -f $file;
        return LoadFile($file);
    },
);

sub get {
    my ($self, $key, @args) = @_;
    my $str = $self->_strings->{$key};
    return $key unless defined $str;
    return @args ? sprintf($str, @args) : $str;
}

=method get

    my $string = $strings->get($key);
    my $string = $strings->get($key, @sprintf_args);

Get localized string by key. If C<@sprintf_args> are provided, applies C<sprintf>
formatting to the string.

Returns the key itself if not found in strings file (graceful degradation).

Examples:

    $strings->get('title');                    # "WWW::Bund CLI"
    $strings->get('err_unknown_api', 'foo');   # "Unknown API: foo"

=cut

1;
