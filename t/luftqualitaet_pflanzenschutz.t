#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use FindBin;
use YAML::PP qw(LoadFile);

use WWW::Bund::Registry;

# Offline regression guard for karr k7: luftqualitaet + pflanzenschutz.
#
# 1. Endpoint-data integrity for both APIs, pinned to the published OpenAPI
#    specs (base_url + query params). Live verification found NO drift on
#    2026-09; this locks that state so a future edit that reintroduces drift
#    fails here instead of only in an opt-in live test.
# 2. The six pflanzenschutz render templates are now loadable .yml files
#    (type: table + extract: items), not the old unloaded .yaml stubs, in all
#    seven languages.
# 3. Eleven of the thirteen luftqualitaet endpoints render as a table too
#    (type: keyed_matrix), their .yaml stub is gone. The two endpoints
#    airquality and meta keep the YAML fallback: their shape has no flat
#    header row, so they have no .yml and no .yaml stub either.

my $share = File::Spec->catdir($FindBin::Bin, '..', 'share');
my $reg = WWW::Bund::Registry->new(
    registry_file  => File::Spec->catfile($share, 'registry.yml'),
    endpoints_file => File::Spec->catfile($share, 'endpoints.yml'),
);

# --- 1. Endpoint-data integrity vs the OpenAPI specs -----------------------

my $psm_base  = 'https://psm-api.bvl.bund.de/ords/psm/api-v1';
my $uba_base  = 'https://www.umweltbundesamt.de/api/air_data/v2';

my %expected = (
    # pflanzenschutzmittelzulassung
    pflanzenschutzmittelzulassung_mittel    => [$psm_base, [qw(kennr)]],
    pflanzenschutzmittelzulassung_wirkstoff => [$psm_base, [qw(wirknr)]],
    pflanzenschutzmittelzulassung_awg       => [$psm_base, [qw(awg_id kennr)]],
    pflanzenschutzmittelzulassung_antrag    => [$psm_base, [qw(antragnr antragsteller_nr kennr)]],
    pflanzenschutzmittelzulassung_kode      => [$psm_base, [qw(kode kodeliste sprache)]],
    pflanzenschutzmittelzulassung_stand     => [$psm_base, []],
    # luftqualitaet
    luftqualitaet_airquality         => [$uba_base, [qw(date_from time_from date_to time_to station)]],
    luftqualitaet_airquality_limits  => [$uba_base, []],
    luftqualitaet_annualbalances     => [$uba_base, [qw(component year lang)]],
    luftqualitaet_components         => [$uba_base, [qw(lang index)]],
    luftqualitaet_measures           => [$uba_base, [qw(date_from time_from date_to time_to station component scope)]],
    luftqualitaet_measures_limits    => [$uba_base, []],
    luftqualitaet_networks           => [$uba_base, [qw(lang index)]],
    luftqualitaet_scopes             => [$uba_base, [qw(lang index)]],
    luftqualitaet_stationsettings    => [$uba_base, [qw(lang)]],
    luftqualitaet_stationtypes       => [$uba_base, [qw(lang)]],
    luftqualitaet_thresholds         => [$uba_base, [qw(use lang component scope)]],
    luftqualitaet_transgressions     => [$uba_base, [qw(component year lang index)]],
    luftqualitaet_meta               => [$uba_base, [qw(use lang date_from date_to time_from time_to)]],
);

for my $name (sort keys %expected) {
    my ($base, $qp) = @{ $expected{$name} };
    my $ep = $reg->endpoint($name);
    is($ep->{base_url}, $base, "$name base_url matches spec");
    is(lc($ep->{method} // 'get'), 'get', "$name is GET");
    is_deeply($ep->{query_params} // [], $qp, "$name query params match spec");
}

# --- 2. pflanzenschutz render templates are functional .yml ----------------

my @langs = qw(de en fr es it nl pl);

my %cols = (
    stand     => [qw(datum)],
    mittel    => [qw(kennr mittelname formulierung_art zul_ende)],
    wirkstoff => [qw(wirknr wirkstoffname wirkstoffname_en genehmigt)],
    awg       => [qw(awg_id kennr anwendungsbereich kultur_erl)],
    antrag    => [qw(kennr antragnr antragsteller antragsteller_nr)],
    kode      => [qw(kode kodeliste kodetext sprache)],
);

for my $lang (@langs) {
    for my $ep (sort keys %cols) {
        my $stem = "pflanzenschutzmittelzulassung_$ep";
        my $yml  = File::Spec->catfile($share, 'templates', $lang, "$stem.yml");
        my $yaml = File::Spec->catfile($share, 'templates', $lang, "$stem.yaml");

        ok(-f $yml,   "$lang/$stem.yml exists (loadable by the formatter)");
        ok(!-e $yaml, "$lang/$stem.yaml stub is gone");

        my $t = eval { LoadFile($yml) };
        ok($t, "$lang/$stem.yml parses as YAML") or next;
        is($t->{type},    'table', "$lang/$stem type is table");
        is($t->{extract}, 'items', "$lang/$stem extracts the ORDS items array");
        ok(defined $t->{empty} && length $t->{empty},
            "$lang/$stem keeps a localized empty: message");

        my @fields = map { $_->{field} } @{ $t->{columns} || [] };
        is_deeply(\@fields, $cols{$ep}, "$lang/$stem columns match the chosen fields");
    }
}

# --- 3. luftqualitaet render templates are functional .yml --------------------

# The eleven endpoints that arrive as a header row with numbered or positional
# rows. The header and rows paths are the ones the measured formats of the
# Umweltbundesamt need.
my %matrix = (
    components        => { rows => undef,  header => undef },
    scopes            => { rows => undef,  header => undef },
    stationtypes      => { rows => undef,  header => undef },
    stationsettings   => { rows => undef,  header => undef },
    thresholds        => { rows => undef,  header => undef },
    networks          => { rows => 'data', header => undef },
    annualbalances    => { rows => 'data', header => undef },
    transgressions    => { rows => 'data', header => undef },
    airquality_limits => { rows => 'data', header => undef },
    measures_limits   => { rows => 'data', header => undef },
    measures          => { rows => 'data', header => 'indices.data.station id.date start' },
);

# The empty texts are the ones of the former .yaml stubs, taken over unchanged.
my %empty = (
    de => {
        annualbalances    => 'Keine Jahresbilanzen gefunden.',
        airquality_limits => 'Keine Grenzwerte für Luftqualitätsdaten verfügbar.',
        components        => 'Keine Komponenten.',
        measures          => 'Keine Messwerte verfügbar.',
        measures_limits   => 'Keine Grenzwerte für Messungen verfügbar.',
        networks          => 'Keine Netzwerke gefunden.',
        scopes            => 'Keine Bereiche gefunden.',
        stationsettings   => 'Keine Stationseinstellungen gefunden.',
        stationtypes      => 'Keine Stationstypen gefunden.',
        thresholds        => 'Keine Schwellenwerte verfügbar.',
        transgressions    => 'Keine Überschreitungen verfügbar.',
    },
    en => {
        annualbalances    => 'No annual balances found.',
        airquality_limits => 'No air quality data limits available.',
        components        => 'No components.',
        measures          => 'No measurements available.',
        measures_limits   => 'No measurement limits available.',
        networks          => 'No networks found.',
        scopes            => 'No scopes found.',
        stationsettings   => 'No station settings found.',
        stationtypes      => 'No station types found.',
        thresholds        => 'No thresholds available.',
        transgressions    => 'No transgressions available.',
    },
    fr => {
        annualbalances    => 'Aucun bilan annuel trouvé.',
        airquality_limits => "Aucune limite de données de qualité de l'air disponible.",
        components        => 'Aucun composant trouvé.',
        measures          => 'Aucune mesure trouvée.',
        measures_limits   => 'Aucune limite de mesure disponible.',
        networks          => 'Aucun réseau trouvé.',
        scopes            => 'Aucune portée trouvée.',
        stationsettings   => 'Aucun paramètre de station trouvé.',
        stationtypes      => 'Aucun type de station trouvé.',
        thresholds        => 'Aucun seuil disponible.',
        transgressions    => 'Aucun dépassement disponible.',
    },
    es => {
        annualbalances    => 'No se encontraron balances anuales.',
        airquality_limits => 'No hay límites de datos de calidad del aire disponibles.',
        components        => 'No se encontraron componentes.',
        measures          => 'No se encontraron medidas.',
        measures_limits   => 'No hay límites de medición disponibles.',
        networks          => 'No se encontraron redes.',
        scopes            => 'No se encontraron ámbitos.',
        stationsettings   => 'No se encontraron configuraciones de estación.',
        stationtypes      => 'No se encontraron tipos de estación.',
        thresholds        => 'No hay umbrales disponibles.',
        transgressions    => 'No hay transgresiones disponibles.',
    },
    it => {
        annualbalances    => 'Nessun bilancio annuale trovato.',
        airquality_limits => "Nessun limite di dati sulla qualità dell'aria disponibile.",
        components        => 'Nessun componente trovato.',
        measures          => 'Nessuna misura trovata.',
        measures_limits   => 'Nessun limite di misurazione disponibile.',
        networks          => 'Nessuna rete trovata.',
        scopes            => 'Nessun ambito trovato.',
        stationsettings   => 'Nessuna impostazione di stazione trovata.',
        stationtypes      => 'Nessun tipo di stazione trovato.',
        thresholds        => 'Nessuna soglia disponibile.',
        transgressions    => 'Nessun superamento disponibile.',
    },
    nl => {
        annualbalances    => 'Geen jaarbalansen gevonden.',
        airquality_limits => 'Geen limieten voor luchtkwaliteitsgegevens beschikbaar.',
        components        => 'Geen componenten gevonden.',
        measures          => 'Geen maatregelen gevonden.',
        measures_limits   => 'Geen meetlimieten beschikbaar.',
        networks          => 'Geen netwerken gevonden.',
        scopes            => 'Geen bereiken gevonden.',
        stationsettings   => 'Geen stationinstellingen gevonden.',
        stationtypes      => 'Geen stationtypes gevonden.',
        thresholds        => 'Geen drempelwaarden beschikbaar.',
        transgressions    => 'Geen overschrijdingen beschikbaar.',
    },
    pl => {
        annualbalances    => 'Nie znaleziono bilansów rocznych.',
        airquality_limits => 'Brak dostępnych limitów danych o jakości powietrza.',
        components        => 'Nie znaleziono komponentów.',
        measures          => 'Nie znaleziono środków.',
        measures_limits   => 'Brak dostępnych limitów pomiarów.',
        networks          => 'Nie znaleziono sieci.',
        scopes            => 'Nie znaleziono zakresów.',
        stationsettings   => 'Nie znaleziono ustawień stacji.',
        stationtypes      => 'Nie znaleziono typów stacji.',
        thresholds        => 'Brak dostępnych progów.',
        transgressions    => 'Brak dostępnych przekroczeń.',
    },
);

for my $lang (@langs) {
    for my $ep (sort keys %matrix) {
        my $stem = "luftqualitaet_$ep";
        my $yml  = File::Spec->catfile($share, 'templates', $lang, "$stem.yml");
        my $yaml = File::Spec->catfile($share, 'templates', $lang, "$stem.yaml");

        ok(-f $yml,   "$lang/$stem.yml exists (loadable by the formatter)");
        ok(!-e $yaml, "$lang/$stem.yaml stub is gone");

        my $t = eval { LoadFile($yml) };
        ok($t, "$lang/$stem.yml parses as YAML") or next;
        is($t->{type}, 'keyed_matrix', "$lang/$stem type is keyed_matrix");
        ok($t->{row_key}, "$lang/$stem shows the key column");
        is($t->{header}, $matrix{$ep}{header}, "$lang/$stem header path");
        is($t->{rows},   $matrix{$ep}{rows},   "$lang/$stem rows path");
        is($t->{empty},  $empty{$lang}{$ep},   "$lang/$stem keeps the empty text of the stub");
    }
}

# airquality and meta have no flat header row, so they keep the YAML fallback:
# no .yml and no .yaml stub either, the answer is shown as it is.
for my $lang (@langs) {
    for my $ep (qw(airquality meta)) {
        my $yml  = File::Spec->catfile($share, 'templates', $lang, "luftqualitaet_$ep.yml");
        my $yaml = File::Spec->catfile($share, 'templates', $lang, "luftqualitaet_$ep.yaml");

        ok(!-e $yml,  "$lang/luftqualitaet_$ep has no .yml (stays a YAML fallback)");
        ok(!-e $yaml, "$lang/luftqualitaet_$ep.yaml stub is gone");
    }
}

done_testing;
