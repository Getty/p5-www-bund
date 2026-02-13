package WWW::Bund::API::DWD;
our $VERSION = '0.002';
# ABSTRACT: Adapter for DWD API (weather data)

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund;

    my $bund = WWW::Bund->new;
    my $dwd = $bund->dwd;

    # Weather stations
    my $stations = $dwd->station_overview;
    my $stations = $dwd->station_overview(stationIds => '10865');

    # Weather warnings
    my $nowcast = $dwd->warnings_nowcast;
    my $municipality = $dwd->municipality_warnings;
    my $coast = $dwd->coast_warnings;

    # Crowd-sourced reports
    my $reports = $dwd->crowd_reports;

=head1 DESCRIPTION

Type-safe adapter for the DWD (Deutscher Wetterdienst / German Weather Service)
API. Provides access to weather warnings, station data, and crowd-sourced
weather reports.

=cut

has client => (is => 'ro', required => 1, weak_ref => 1);

=attr client

L<WWW::Bund> client instance. Required. Weak reference.

=cut

sub station_overview {
    my ($self, %params) = @_;
    $self->client->call('dwd', 'dwd_station_overview',
        %params ? (params => \%params) : (),
    );
}

=method station_overview

    my $stations = $dwd->station_overview;
    my $station = $dwd->station_overview(stationIds => '10865');

Get overview of weather stations. Can filter by station IDs.

=cut

sub warnings_nowcast {
    my ($self) = @_;
    $self->client->call('dwd', 'dwd_warnings_nowcast');
}

=method warnings_nowcast

Get current weather warnings (nowcast).

=cut

sub municipality_warnings {
    my ($self) = @_;
    $self->client->call('dwd', 'dwd_municipality_warnings');
}

=method municipality_warnings

Get weather warnings by municipality (Gemeinde).

=cut

sub coast_warnings {
    my ($self) = @_;
    $self->client->call('dwd', 'dwd_coast_warnings');
}

=method coast_warnings

Get coastal weather warnings (Küstenwarnungen).

=cut

sub crowd_reports {
    my ($self) = @_;
    $self->client->call('dwd', 'dwd_crowd_reports');
}

=method crowd_reports

Get crowd-sourced weather reports.

=cut

1;
