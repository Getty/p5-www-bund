use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use YAML::PP qw(LoadFile);

use WWW::Bund::CLI::Formatter;

# Offline test of the templates of the Ladestationen and the Bundeshaushalt.
#
# The shapes of the answers were measured on 2026-10-20 (the answers are
# written into the test as Perl data structures, nothing is fetched):
#
#   ladestationen_query         a GeoJSON FeatureCollection of the ArcGIS
#                               layer of the Ladesaeulenregister: the fields
#                               of a station are in properties. The OpenAPI
#                               spec describes them under attributes, that
#                               is the Esri variant with f=json; the names
#                               are the same.
#   bundeshaushalt_budget_data  the tree view of the federal budget: meta
#                               says what is delivered (Budget, Section,
#                               Chapter) and on which level one stands,
#                               detail holds the values of the node and
#                               parents the path to it. With the mandatory
#                               parameters (year, account) the answer is the
#                               top level, so detail is empty.
#
# The call of the Ladestationen endpoint needs a token (LADESTATIONEN_TOKEN),
# so the answer of that endpoint is a fixture here - the test never calls the
# API.
#
# The template of an endpoint lives in share/templates/{lang}/{endpoint}.yml.
# The loader of the formatter reads .yml only, so the .yaml placeholders of
# these endpoints were ignored and the CLI answered with a raw YAML dump.
#
# A field of the type record that holds a nested structure - detail and
# parents of the budget - is written as compact JSON: an empty line would
# hide the value.

my @LANGS = qw(de en fr es it nl pl);

# The type of the template, the path it reads from the answer and the fields
# of its columns. The names of the fields are the ones the API delivers, they
# are not translated.
my %ENDPOINTS = (
    ladestationen_query => {
        type    => 'table',
        extract => 'features',
        fields  => [
            'properties.für_die_Überschrift_',
            'properties.Betreiber_',
            'properties.Standort_',
            'properties.Anzahl_Ladepunkte_',
            'properties.Art_des_Ladepunktes_',
        ],
    },
    bundeshaushalt_budget_data => {
        type    => 'record',
        extract => undef,
        fields  => [
            'meta.year',
            'meta.quota',
            'meta.unit',
            'meta.entity',
            'meta.modifyDate',
            'detail',
            'parents',
        ],
    },
);

# The measured answers of the endpoints. The fields of a station are named as
# the OpenAPI spec of the Ladesaeulenregister names them.
my %ANSWER = (
    ladestationen_query => {
        type     => 'FeatureCollection',
        features => [
            {
                type       => 'Feature',
                geometry   => { type => 'Point', coordinates => [ 11.5820, 48.1350 ] },
                properties => {
                    ID                       => 1,
                    Betreiber_               => 'Stadtwerke München GmbH',
                    Standort_                => 'Musterstraße 1, 80331 München',
                    Längengrad_              => 11.5820,
                    Breitengrad_             => 48.1350,
                    für_die_Überschrift_     => 'Ladesäule 1, München',
                    Anzahl_Ladepunkte_       => '2',
                    Art_des_Ladepunktes_     => 'AC',
                    Nennleistung_Ladepunkt_1_ => '22',
                    Public_Key__1_           => 'DE*SWM*E42*0001',
                    AC_Steckdose_Typ_2__1_   => 'ja',
                },
            },
            {
                type       => 'Feature',
                geometry   => { type => 'Point', coordinates => [ 13.4105, 52.5244 ] },
                properties => {
                    ID                       => 2,
                    Betreiber_               => 'Stadtwerke Berlin AG',
                    Standort_                => 'Beispielweg 2, 10115 Berlin',
                    Längengrad_              => 13.4105,
                    Breitengrad_             => 52.5244,
                    für_die_Überschrift_     => 'Ladesäule 2, Berlin',
                    Anzahl_Ladepunkte_       => '4',
                    Art_des_Ladepunktes_     => 'DC',
                    Nennleistung_Ladepunkt_1_ => '50',
                    Public_Key__1_           => 'DE*BWB*E42*0002',
                    DC_Kupplung_Combo__1_    => 'ja',
                },
            },
        ],
    },
    bundeshaushalt_budget_data => {
        meta => {
            year       => 2025,
            unit       => 'single',
            quota      => 'target',
            account    => undef,
            timestamp  => 1759405122000,
            modifyDate => '02.10.2025',
            entity     => 'Chapter',
            levelCur   => 2,
            levelMax   => 3,
        },
        detail  => {},
        parents => [
            [ { id => undef, label => 'Sollwerte des Haushaltsjahres 2025' } ],
            [],
            [],
        ],
    },
);

my $templates_dir = File::Spec->catdir($FindBin::Bin, '..', 'share', 'templates');
my $strings_dir   = File::Spec->catdir($FindBin::Bin, '..', 'share', 'strings');

sub formatter {
    my ($lang) = @_;
    return WWW::Bund::CLI::Formatter->new(
        templates_dir => $templates_dir,
        strings_dir   => $strings_dir,
        lang          => $lang,
    );
}

# The text of a template: the headers of its columns and its empty message.
sub text_of {
    my ($template) = @_;
    my @headers = map { $_->{header} // $_->{label} // '' }
                  @{ $template->{columns} || $template->{fields} || [] };
    return join '|', @headers, ($template->{empty} // '');
}

# --- every endpoint has a template in every language -------------------------
for my $endpoint (sort keys %ENDPOINTS) {
    my $spec = $ENDPOINTS{$endpoint};
    my %text;

    for my $lang (@LANGS) {
        my $file = File::Spec->catfile($templates_dir, $lang, "$endpoint.yml");

        ok(-f $file, "$endpoint: the template for $lang exists");

        # A missing file is no error here, the assertions below report it.
        my $template = {};
        my $error    = 'the file does not exist';
        if (-f $file) {
            $template = eval { LoadFile($file) };
            $error = $@;
            $template ||= {};
        }
        ok(!$error, "$endpoint/$lang: the template is readable as YAML");

        is($template->{type}, $spec->{type},
            "$endpoint/$lang: the template is a $spec->{type}");

        if (exists $spec->{extract}) {
            is($template->{extract}, $spec->{extract},
                $spec->{extract}
                ? "$endpoint/$lang: the template reads $spec->{extract}"
                : "$endpoint/$lang: the template reads no path");
        }

        my $columns = $template->{columns} || $template->{fields} || [];
        is_deeply(
            [map { ref $_ eq 'HASH' ? $_->{field} : undef } @$columns],
            $spec->{fields},
            "$endpoint/$lang: the fields are " . join(', ', @{ $spec->{fields} })
        );

        my $empty = $template->{empty};
        ok(defined $empty && length $empty,
            "$endpoint/$lang: the template has an empty message");

        $text{$lang} = text_of($template);
    }

    for my $lang (grep { $_ ne 'de' } @LANGS) {
        isnt($text{$lang}, $text{de},
            "$endpoint/$lang: the template is translated, not copied from the German one");
    }
}

# --- the Ladestationen answer is rendered as a table -------------------------
{
    my $fmt = formatter('de');
    my $out = $fmt->format_output($ANSWER{ladestationen_query}, 'ladestationen_query', 'template');

    unlike($out, qr/features:/, 'ladestationen_query: the answer is no YAML dump');
    like($out, qr/^-{4,}$/m, 'ladestationen_query: the answer is a table');

    for my $feature (@{ $ANSWER{ladestationen_query}{features} }) {
        my $station = $feature->{properties}{für_die_Überschrift_};
        like($out, qr/^\Q$station\E\s+/m,
            "ladestationen_query: the row shows $station");
        like($out, qr/\Q$feature->{properties}{Betreiber_}\E/,
            "ladestationen_query: the row shows the operator of $station");
        like($out, qr/\Q$feature->{properties}{Anzahl_Ladepunkte_}\E/,
            "ladestationen_query: the row shows the number of charging points of $station");
    }

    # A table of two rows has a header and two rows.
    my @rows = grep { /\S/ && !/^-/ } split /\n/, $out;
    is(scalar @rows, 3, 'ladestationen_query: the table has a header and two rows');
}

# --- the Bundeshaushalt answer is rendered as a record -----------------------
{
    my $fmt = formatter('de');
    my $out = $fmt->format_output($ANSWER{bundeshaushalt_budget_data}, 'bundeshaushalt_budget_data', 'template');

    unlike($out, qr/meta:/, 'bundeshaushalt_budget_data: the answer is no YAML dump');

    like($out, qr/^Jahr\s+2025$/m,
        'bundeshaushalt_budget_data: the answer shows the year');
    like($out, qr/^Kontenart\s+target$/m,
        'bundeshaushalt_budget_data: the answer shows the quota');
    like($out, qr/^Einheit\s+single$/m,
        'bundeshaushalt_budget_data: the answer shows the unit');
    like($out, qr/^Ebene\s+Chapter$/m,
        'bundeshaushalt_budget_data: the answer shows the level');
    like($out, qr/^Stand\s+02\.10\.2025$/m,
        'bundeshaushalt_budget_data: the answer shows the date of the state');

    # The nested structures are shown as compact JSON, an empty line would
    # hide the value.
    like($out, qr/^Details\s+\{\}$/m,
        'bundeshaushalt_budget_data: the detail is shown as JSON');
    like($out, qr/^Übergeordnete Knoten\s+\[\[\{"id":null,"label":"Sollwerte des Haushaltsjahres 2025"\}\],\[\],\[\]\]$/m,
        'bundeshaushalt_budget_data: the parents are shown as JSON');
}

# --- the empty message of the template is used -------------------------------
{
    my $fmt = formatter('de');

    my $file     = File::Spec->catfile($templates_dir, 'de', 'ladestationen_query.yml');
    my $template = -f $file ? LoadFile($file) : {};

    # Without a template there is no message - the answer would be a dump.
    my $empty = $template->{empty} // 'the template has no empty message';
    my $out   = $fmt->format_output(
        { type => 'FeatureCollection', features => [] },
        'ladestationen_query',
        'template'
    );

    like($out, qr/\Q$empty\E/,
        'ladestationen_query: the empty message of the template is used');
}

done_testing;
