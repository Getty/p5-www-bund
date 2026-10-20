use strict;
use warnings;
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
#    seven languages. luftqualitaet templates are deliberately left as .yaml
#    stubs (the UBA response shape needs a formatter type that does not yet
#    exist), so they must NOT have grown a .yml sibling.

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

# luftqualitaet templates must stay as .yaml stubs (no .yml sibling), since the
# UBA response shape is not renderable by the current formatter.
my @luft = qw(
    airquality airquality_limits annualbalances components measures
    measures_limits networks scopes stationsettings stationtypes
    thresholds transgressions meta
);
for my $lang (@langs) {
    for my $ep (@luft) {
        my $yml = File::Spec->catfile($share, 'templates', $lang, "luftqualitaet_$ep.yml");
        ok(!-e $yml, "$lang/luftqualitaet_$ep has no .yml (stays a YAML-fallback stub)");
    }
}

done_testing;
