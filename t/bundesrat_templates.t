use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use YAML::PP qw(LoadFile);

use WWW::Bund::CLI::Formatter;

# The Bundesrat endpoints answer with XML (view=renderXml). The shapes of the
# answers were measured on 2026-10-20 with the XML parser of the repository:
#
#   bundesrat_startlist   list.item[]     name, date, layoutDate, md5, url
#   bundesrat_aktuelles   list.item[]     date, dateOfIssue, title, bodyText, type, id, url, detail, highlighted, imgDates
#   bundesrat_termine     list.item[]     title, description, startdate, stopdate, type, id, url, detail
#   bundesrat_mitglieder  list.employee[] name, firstname, honorificTitle, party, state, brmitglied, bv, designiert, mitglied, imagePath, imageDate, detailImgDates, url, detail
#   bundesrat_praesidium  list.item[]     title, imageCaption, imagePath, date, dateOfIssue, abstract, detail, id, type
#
# The fields detail and bodyText carry HTML and stay out of the templates.
#
# The template of an endpoint lives in share/templates/{lang}/{endpoint}.yml.
# The loader of the formatter reads .yml only, so the .yaml placeholders of
# these endpoints were ignored and the CLI answered with a raw YAML dump.
#
# Offline: nothing is fetched, the measured answers are written into the test
# as Perl data structures.

my @LANGS = qw(de en fr es it nl pl);

my %ENDPOINTS = (
    bundesrat_startlist => {
        type    => 'table',
        extract => 'list.item',
        columns => [qw(name date url)],
    },
    bundesrat_aktuelles => {
        type    => 'table',
        extract => 'list.item',
        columns => [qw(date title type url)],
    },
    bundesrat_termine => {
        type    => 'table',
        extract => 'list.item',
        columns => [qw(startdate title description)],
    },
    bundesrat_mitglieder => {
        type    => 'table',
        extract => 'list.employee',
        columns => [qw(name firstname party state)],
    },
    bundesrat_praesidium => {
        type    => 'table',
        extract => 'list.item',
        columns => [qw(title imageCaption imagePath date)],
    },
);

# The measured answers of the three endpoints that are rendered below.
my %ANSWER = (
    bundesrat_startlist => {
        list => {
            item => [
                {
                    date       => '24.02.2026 15:57:19',
                    layoutDate => '13.05.2017 13:25:00',
                    md5        => 'kaev8wfv4QqBvjHrPzoMjQ==',
                    name       => 'iOS_iPhone_css',
                    url        => 'https://www.bundesrat.de/iOS/v3/AppGlobals/iOS_iPhone_css.css?view=renderCSS&v=19',
                },
                {
                    date       => '20.10.2026 08:15:00',
                    layoutDate => '18.11.2022 17:00:00',
                    md5        => 'kaev8wfv4QqBvjHrPzoMjQ==',
                    name       => 'Einstellungen',
                    url        => 'https://www.bundesrat.de/iOS/v3/AppGlobals/Einstellungen.xml?view=render[iOSDetailsWithoutInnerDate]',
                },
            ],
        },
    },
    bundesrat_mitglieder => {
        list => {
            employee => [
                {
                    brmitglied     => 'true',
                    bv             => 'false',
                    designiert     => 'false',
                    firstname      => 'Cem',
                    honorificTitle => '',
                    imageDate      => '13.05.2026 11:41',
                    imagePath      => 'https://www.bundesrat.de/SharedDocs/bilder/personen/laender/bw/oezdemir.jpg?__blob=poster&v=1',
                    mitglied       => 'true',
                    name           => 'Özdemir',
                    party          => 'BÜNDNIS 90/DIE GRÜNEN',
                    state          => 'Baden-Württemberg',
                    url            => 'https://www.bundesrat.de/SharedDocs/personen/DE/laender/bw/oezdemir-cem.html',
                },
                {
                    brmitglied     => 'true',
                    bv             => 'false',
                    designiert     => 'false',
                    firstname      => 'Katharina',
                    honorificTitle => '',
                    imageDate      => '16.04.2025 15:24',
                    imagePath      => 'https://www.bundesrat.de/SharedDocs/bilder/personen/laender/be/guenther-wuensch.jpg?__blob=poster&v=3',
                    mitglied       => 'false',
                    name           => 'Günther-Wünsch',
                    party          => 'CDU',
                    state          => 'Berlin',
                    url            => 'https://www.bundesrat.de/SharedDocs/personen/DE/laender/be/guenther-wuensch-katharina.html',
                },
            ],
        },
    },
    bundesrat_praesidium => {
        list => {
            item => [
                {
                    abstract     => '',
                    date         => '25.09.2026 11:59',
                    dateOfIssue  => '01.11.2025 06:58',
                    id           => '/BR/iOS/v3/05_Bundesrat/Praesidium/VorsitzText',
                    imageCaption => 'Bundesrat',
                    imagePath    => 'https://www.bundesrat.de/iOS/SharedDocs/Bilder/praesidium-2024.jpg?__blob=normal&v=4',
                    imageSource  => '',
                    imgDates     => '31.10.2025 14:13',
                    title        => 'muenzeVorsitz',
                    type         => 'Basepage',
                },
                {
                    abstract     => '',
                    date         => '25.09.2026 10:08',
                    dateOfIssue  => '01.11.2023 06:58',
                    id           => '/BR/iOS/v3/05_Bundesrat/Praesidium/bundesrat_praesidium_sekretariat_direktor',
                    imageCaption => 'Bundesrat',
                    imagePath    => 'https://www.bundesrat.de/iOS/SharedDocs/Bilder/direktoren.png?__blob=normal&v=2',
                    imageSource  => '',
                    imgDates     => '29.08.2023 21:12',
                    title        => 'muenzeFooter',
                    type         => 'Basepage',
                },
            ],
        },
    },
);

my $templates_dir = File::Spec->catdir($FindBin::Bin, '..', 'share', 'templates');
my $strings_dir   = File::Spec->catdir($FindBin::Bin, '..', 'share', 'strings');

# --- every endpoint has a template in every language -------------------------
for my $endpoint (sort keys %ENDPOINTS) {
    my $spec = $ENDPOINTS{$endpoint};

    for my $lang (@LANGS) {
        my $file = File::Spec->catfile($templates_dir, $lang, "$endpoint.yml");

        ok(-f $file, "$endpoint: the template for $lang exists");

        my $template = -f $file ? eval { LoadFile($file) } : undef;
        ok(!$@, "$endpoint/$lang: the template is readable as YAML");

        is($template ? $template->{type} : undef, $spec->{type},
            "$endpoint/$lang: the template is a $spec->{type}");

        is($template ? $template->{extract} : undef, $spec->{extract},
            "$endpoint/$lang: the template reads $spec->{extract}");

        my $empty = $template ? $template->{empty} : undef;
        ok(defined $empty && length $empty,
            "$endpoint/$lang: the template has an empty message");

        my $columns = $template && $template->{columns} ? $template->{columns} : [];
        is_deeply(
            [map { ref $_ eq 'HASH' ? $_->{field} : undef } @$columns],
            $spec->{columns},
            "$endpoint/$lang: the columns are " . join(', ', $spec->{columns})
        );
    }
}

# --- the measured answers are rendered as a table ---------------------------
sub formatter {
    my ($lang) = @_;
    return WWW::Bund::CLI::Formatter->new(
        templates_dir => $templates_dir,
        strings_dir   => $strings_dir,
        lang          => $lang,
    );
}

# The header row of the table: the headers of the template in their order.
sub header_regex {
    my ($template) = @_;
    my @headers = $template && $template->{columns}
        ? map { $_->{header} // uc($_->{field}) } @{ $template->{columns} }
        : ();
    return qr/(?!)/ unless @headers;
    return qr/\b@{[ join '\s+', map { quotemeta $_ } @headers ]}\b/;
}

# The cells of a rendered row: the columns are separated by two spaces, the
# value of a cell is padded to the width of the column.
sub cells {
    my ($line) = @_;
    return [map { my $c = $_; $c =~ s/\A\s+//; $c =~ s/\s+\z//; $c } split /\s{2,}/, $line];
}

for my $endpoint (qw(bundesrat_startlist bundesrat_mitglieder bundesrat_praesidium)) {
    my $spec = $ENDPOINTS{$endpoint};
    my $kind = (split /\./, $spec->{extract})[-1];
    my @rows = @{ $ANSWER{$endpoint}{list}{$kind} };

    for my $lang (qw(de en)) {
        my $file = File::Spec->catfile($templates_dir, $lang, "$endpoint.yml");
        my $template = -f $file ? LoadFile($file) : {};

        my $fmt = formatter($lang);
        my $out = $fmt->format_output($ANSWER{$endpoint}, $endpoint, 'template');

        unlike($out, qr/^\s*-\s/m, "$endpoint/$lang: the answer is no YAML dump");
        like($out, qr/^-{3,}$/m, "$endpoint/$lang: the answer is a table");

        like($out, header_regex($template),
            "$endpoint/$lang: the table carries the headers of the template");

        # The table is a header, a rule and one line per row
        my @lines = split /\n/, $out;
        is(scalar @lines, 2 + scalar @rows,
            "$endpoint/$lang: every row of the answer is rendered in a line");

        my @data_lines = @lines > 2 ? @lines[2 .. $#lines] : ();

        for my $i (0 .. $#rows) {
            my @expected = map { $rows[$i]{$_} } @{ $spec->{columns} };
            is_deeply(cells($data_lines[$i] // ''), \@expected,
                "$endpoint/$lang: row " . ($i + 1) . " is rendered with all its values");
        }

        # The empty message of the template is used when the answer is empty
        my $empty_out = $fmt->format_output({ list => { $kind => [] } }, $endpoint, 'template');
        is($empty_out, ($template->{empty} // '') . "\n",
            "$endpoint/$lang: the empty message of the template is used");
    }
}

done_testing;
