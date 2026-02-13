package WWW::Bund::API::Tagesschau;

# ABSTRACT: Adapter for Tagesschau API (news)

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund;

    my $bund = WWW::Bund->new;
    my $tagesschau = $bund->tagesschau;

    # Get homepage news
    my $homepage = $tagesschau->homepage;

    # Get all news (optionally filtered)
    my $news = $tagesschau->news;
    my $news = $tagesschau->news(regions => 1);

    # Search news
    my $results = $tagesschau->search('Bundestag');

    # List available channels
    my $channels = $tagesschau->channels;

=head1 DESCRIPTION

Type-safe adapter for the Tagesschau API, providing access to news articles
from Germany's main public broadcasting news service.

=cut

has client => (is => 'ro', required => 1, weak_ref => 1);

=attr client

L<WWW::Bund> client instance. Required. Weak reference.

=cut

sub homepage {
    my ($self) = @_;
    $self->client->call('tagesschau', 'tagesschau_homepage');
}

=method homepage

    my $homepage = $tagesschau->homepage;

Get news from the homepage. Returns HashRef with news, regional, and video sections.

=cut

sub news {
    my ($self, %params) = @_;
    $self->client->call('tagesschau', 'tagesschau_news',
        %params ? (params => \%params) : (),
    );
}

=method news

    my $news = $tagesschau->news;
    my $news = $tagesschau->news(regions => 1);

Get all news articles. Optional query parameters can filter results.

=cut

sub search {
    my ($self, $query) = @_;
    $self->client->call('tagesschau', 'tagesschau_search',
        params => { searchText => $query },
    );
}

=method search

    my $results = $tagesschau->search($query);

Search news articles by keyword. Returns ArrayRef of matching articles.

=cut

sub channels {
    my ($self) = @_;
    $self->client->call('tagesschau', 'tagesschau_channels');
}

=method channels

    my $channels = $tagesschau->channels;

List available news channels/categories.

=cut

1;
