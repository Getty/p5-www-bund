package WWW::Bund::API::Bundestag;
our $VERSION = '0.002';
# ABSTRACT: Adapter for Bundestag API (parliament data)

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund;

    my $bund = WWW::Bund->new;
    my $bundestag = $bund->bundestag;

    # General info
    my $speaker = $bundestag->speaker;
    my $conferences = $bundestag->conferences;

    # Committees (Ausschüsse)
    my $committees = $bundestag->ausschuesse;
    my $committee = $bundestag->ausschuss($id);

    # Members of Parliament (MdB)
    my $mdb_index = $bundestag->mdb_index;
    my $biography = $bundestag->mdb_bio($mdb_id);

    # Content
    my $article = $bundestag->article($article_id);
    my $videos = $bundestag->video_feed;

=head1 DESCRIPTION

Type-safe adapter for the Bundestag API, providing access to German Federal
Parliament (Bundestag) data including members, committees, and proceedings.

Note: This API returns XML responses which are parsed to HashRef.

=cut

has client => (is => 'ro', required => 1, weak_ref => 1);

=attr client

L<WWW::Bund> client instance. Required. Weak reference.

=cut

sub speaker {
    my ($self) = @_;
    $self->client->call('bundestag', 'bundestag_speaker');
}

=method speaker

Get information about the Bundestag speaker (Bundestagspräsident).

=cut

sub conferences {
    my ($self) = @_;
    $self->client->call('bundestag', 'bundestag_conferences');
}

=method conferences

List upcoming and recent Bundestag conferences/sessions.

=cut

sub ausschuesse {
    my ($self) = @_;
    $self->client->call('bundestag', 'bundestag_ausschuesse');
}

=method ausschuesse

List all Bundestag committees (Ausschüsse).

=cut

sub ausschuss {
    my ($self, $id) = @_;
    $self->client->call('bundestag', 'bundestag_ausschuss',
        params => { AUSSCHUSS_ID => $id },
    );
}

=method ausschuss

    my $committee = $bundestag->ausschuss($committee_id);

Get details for a specific committee by ID.

=cut

sub mdb_index {
    my ($self) = @_;
    $self->client->call('bundestag', 'bundestag_mdb_index');
}

=method mdb_index

List all Members of Bundestag (MdB - Mitglieder des Bundestags).

=cut

sub mdb_bio {
    my ($self, $id) = @_;
    $self->client->call('bundestag', 'bundestag_mdb_bio',
        params => { MDB_ID => $id },
    );
}

=method mdb_bio

    my $biography = $bundestag->mdb_bio($mdb_id);

Get biography and details for a specific MdB by ID.

=cut

sub article {
    my ($self, $id) = @_;
    $self->client->call('bundestag', 'bundestag_article',
        params => { ARTICLE_ID => $id },
    );
}

=method article

    my $article = $bundestag->article($article_id);

Get a specific article/document by ID.

=cut

sub video_feed {
    my ($self) = @_;
    $self->client->call('bundestag', 'bundestag_video_feed');
}

=method video_feed

Get video feed of Bundestag proceedings.

=cut

1;
