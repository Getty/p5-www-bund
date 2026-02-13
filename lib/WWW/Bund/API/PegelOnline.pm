package WWW::Bund::API::PegelOnline;

# ABSTRACT: Adapter for Pegel-Online API (water levels)

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund;

    my $bund = WWW::Bund->new;
    my $pegel = $bund->pegel_online;

    # List all gauging stations
    my $stations = $pegel->stations;

    # Get specific station details
    my $station = $pegel->station($uuid);

    # List all waters (rivers, lakes)
    my $waters = $pegel->waters;

    # Get timeseries metadata
    my $ts = $pegel->timeseries($station_uuid, $timeseries_uuid);

    # Get actual measurements
    my $measurements = $pegel->measurements($station_uuid, $timeseries_uuid);

=head1 DESCRIPTION

Type-safe adapter for the Pegel-Online API, providing access to water level
gauges and measurements for German rivers and waterways.

=cut

has client => (is => 'ro', required => 1, weak_ref => 1);

=attr client

L<WWW::Bund> client instance. Required. Weak reference.

=cut

sub stations {
    my ($self) = @_;
    $self->client->call('pegel_online', 'pegel_online_stations');
}

=method stations

    my $stations = $pegel->stations;

List all gauging stations. Returns ArrayRef of station objects with UUID,
name, water, coordinates, etc.

=cut

sub station {
    my ($self, $station) = @_;
    $self->client->call('pegel_online', 'pegel_online_station', params => { station => $station });
}

=method station

    my $station = $pegel->station($uuid);

Get detailed information for a specific station by UUID.

=cut

sub waters {
    my ($self) = @_;
    $self->client->call('pegel_online', 'pegel_online_waters');
}

=method waters

    my $waters = $pegel->waters;

List all waters (rivers, lakes). Returns ArrayRef of water objects.

=cut

sub timeseries {
    my ($self, $station, $timeseries) = @_;
    $self->client->call('pegel_online', 'pegel_online_timeseries',
        params => { station => $station, timeseries => $timeseries },
    );
}

=method timeseries

    my $ts = $pegel->timeseries($station_uuid, $timeseries_uuid);

Get metadata for a specific timeseries (measurement type) at a station.

=cut

sub measurements {
    my ($self, $station, $timeseries) = @_;
    $self->client->call('pegel_online', 'pegel_online_measurements',
        params => { station => $station, timeseries => $timeseries },
    );
}

=method measurements

    my $measurements = $pegel->measurements($station_uuid, $timeseries_uuid);

Get actual water level measurements for a timeseries. Returns ArrayRef of
measurement objects with timestamps and values.

=cut

1;
