package WWW::Bund::API::NINA;
our $VERSION = '0.002';
# ABSTRACT: Adapter for NINA API (disaster warnings)

use Moo;
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund;

    my $bund = WWW::Bund->new;
    my $nina = $bund->nina;

    # Get warnings for region by ARS code
    my $warnings = $nina->dashboard('091620000000');  # Munich

    # Get specific warning details
    my $warning = $nina->warning($identifier);
    my $geojson = $nina->warning_geojson($identifier);

    # Get map data by provider
    my $katwarn = $nina->mapdata_katwarn;
    my $biwapp = $nina->mapdata_biwapp;
    my $mowas = $nina->mapdata_mowas;
    my $dwd = $nina->mapdata_dwd;

    # Metadata
    my $version = $nina->version;
    my $event_codes = $nina->event_codes;

=head1 DESCRIPTION

Type-safe adapter for the NINA (Notfall-Informations- und Nachrichten-App) API.
Provides access to disaster warnings, civil protection alerts, and emergency
information for Germany.

NINA aggregates warnings from multiple providers: KATWARN, BIWAPP, MOWAS (BBK),
DWD (weather warnings), LHP (flood warnings), and police.

=cut

has client => (is => 'ro', required => 1, weak_ref => 1);

=attr client

L<WWW::Bund> client instance. Required. Weak reference.

=cut

sub dashboard {
    my ($self, $ars) = @_;
    $self->client->call('nina', 'nina_warnings', params => { ARS => $ars });
}

=method dashboard

    my $warnings = $nina->dashboard($ars_code);

Get all active warnings for a region by ARS (Amtlicher Regionalschlüssel) code.
Returns ArrayRef of warning objects.

Example: C<091620000000> for Munich.

=cut

sub warning {
    my ($self, $identifier) = @_;
    $self->client->call('nina', 'nina_warning_json', params => { identifier => $identifier });
}

=method warning

    my $warning = $nina->warning($identifier);

Get detailed information for a specific warning by identifier. Returns HashRef
with warning details, affected areas, instructions, etc.

=cut

sub warning_geojson {
    my ($self, $identifier) = @_;
    $self->client->call('nina', 'nina_warning_geojson', params => { identifier => $identifier });
}

=method warning_geojson

    my $geojson = $nina->warning_geojson($identifier);

Get GeoJSON representation of warning area for mapping.

=cut

sub mapdata_katwarn  { shift->client->call('nina', 'nina_mapdata_katwarn') }

=method mapdata_katwarn

Get KATWARN map data for all active warnings.

=cut

sub mapdata_biwapp   { shift->client->call('nina', 'nina_mapdata_biwapp') }

=method mapdata_biwapp

Get BIWAPP map data for all active warnings.

=cut

sub mapdata_mowas    { shift->client->call('nina', 'nina_mapdata_mowas') }

=method mapdata_mowas

Get MOWAS (BBK/Federal Office of Civil Protection) map data.

=cut

sub mapdata_dwd      { shift->client->call('nina', 'nina_mapdata_dwd') }

=method mapdata_dwd

Get DWD (German Weather Service) warnings map data.

=cut

sub mapdata_lhp      { shift->client->call('nina', 'nina_mapdata_lhp') }

=method mapdata_lhp

Get LHP (flood warnings) map data.

=cut

sub mapdata_police   { shift->client->call('nina', 'nina_mapdata_police') }

=method mapdata_police

Get police warnings map data.

=cut

sub version          { shift->client->call('nina', 'nina_version') }

=method version

Get API version information.

=cut

sub logos            { shift->client->call('nina', 'nina_logos') }

=method logos

Get logos/icons for warning providers.

=cut

sub event_codes      { shift->client->call('nina', 'nina_event_codes') }

=method event_codes

Get list of event type codes and descriptions.

=cut

sub notfalltipps     { shift->client->call('nina', 'nina_notfalltipps') }

=method notfalltipps

Get emergency tips and guidelines (Notfalltipps).

=cut

sub faqs             { shift->client->call('nina', 'nina_faqs') }

=method faqs

Get frequently asked questions about NINA.

=cut

1;
