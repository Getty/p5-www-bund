package WWW::Bund::API::Autobahn;
our $VERSION = '0.002';
# ABSTRACT: Adapter for Autobahn API (roadworks, webcams, closures, charging stations)

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund;

    my $bund = WWW::Bund->new;
    my $autobahn = $bund->autobahn;

    # List all Autobahn roads
    my $roads = $autobahn->roads;

    # Get data for specific road
    my $roadworks = $autobahn->roadworks('A7');
    my $webcams = $autobahn->webcams('A7');
    my $warnings = $autobahn->warnings('A7');
    my $closures = $autobahn->closures('A7');
    my $charging = $autobahn->charging_stations('A7');
    my $parking = $autobahn->parking_lorries('A7');

=head1 DESCRIPTION

Type-safe adapter for the Autobahn App API. Provides access to real-time
traffic data for German highways (Autobahns).

All methods return parsed data structures (HashRef or ArrayRef).

=cut

has client => (is => 'ro', required => 1, weak_ref => 1);

=attr client

L<WWW::Bund> client instance. Required. Weak reference to avoid circular refs.

=cut

sub roads {
    my ($self) = @_;
    $self->client->call('autobahn', 'autobahn_roads');
}

=method roads

    my $roads = $autobahn->roads;

List all Autobahn roads (A1, A2, A3, etc.). Returns ArrayRef of road IDs.

=cut

sub roadworks {
    my ($self, $road_id) = @_;
    $self->client->call('autobahn', 'autobahn_roadworks', params => { roadId => $road_id });
}

=method roadworks

    my $roadworks = $autobahn->roadworks('A7');

Get active roadworks (construction sites) for a specific Autobahn. Returns
ArrayRef of roadwork objects with location, description, and duration.

=cut

sub warnings {
    my ($self, $road_id) = @_;
    $self->client->call('autobahn', 'autobahn_warnings', params => { roadId => $road_id });
}

=method warnings

    my $warnings = $autobahn->warnings('A7');

Get traffic warnings (accidents, hazards, etc.) for a specific Autobahn.
Returns ArrayRef of warning objects.

=cut

sub webcams {
    my ($self, $road_id) = @_;
    $self->client->call('autobahn', 'autobahn_webcams', params => { roadId => $road_id });
}

=method webcams

    my $webcams = $autobahn->webcams('A7');

Get traffic webcams for a specific Autobahn. Returns ArrayRef of webcam
objects with coordinates and image URLs.

=cut

sub closures {
    my ($self, $road_id) = @_;
    $self->client->call('autobahn', 'autobahn_closures', params => { roadId => $road_id });
}

=method closures

    my $closures = $autobahn->closures('A7');

Get road closures for a specific Autobahn. Returns ArrayRef of closure objects.

=cut

sub charging_stations {
    my ($self, $road_id) = @_;
    $self->client->call('autobahn', 'autobahn_charging_stations', params => { roadId => $road_id });
}

=method charging_stations

    my $stations = $autobahn->charging_stations('A7');

Get electric vehicle charging stations along a specific Autobahn. Returns
ArrayRef of charging station objects.

=cut

sub parking_lorries {
    my ($self, $road_id) = @_;
    $self->client->call('autobahn', 'autobahn_parking_lorries', params => { roadId => $road_id });
}

=method parking_lorries

    my $parking = $autobahn->parking_lorries('A7');

Get truck/lorry parking areas along a specific Autobahn. Returns ArrayRef of
parking area objects with capacity and availability.

=cut

1;
