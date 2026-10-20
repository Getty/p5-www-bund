use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use YAML::PP qw(LoadFile);

use WWW::Bund::CLI::Formatter;

# The five plenary endpoints of the Bundesrat answer with XML (view=renderXml).
# The shapes of the answers were measured on 2026-10-20 with the XML parser of
# the repository:
#
#   bundesrat_plenum_kompakt           list.tops.top[]  nr, title, subtop, filter,
#                                                      bvgtext, bvgurl, imagePath,
#                                                      imageDate; in addition
#                                                      list.header (a hash)
#   bundesrat_plenum_aktuelle_sitzung  list.top[]       toptitle, topheader,
#                                                      topdrucksache, topurl,
#                                                      linkedtop, topdetail; in
#                                                      addition list.header,
#                                                      list.sitzung, list.stand,
#                                                      list.title
#   bundesrat_plenum_chronologisch     list.header, list.title (scalars only)
#   bundesrat_plenum_naechste_sitzungen one base page: list.item with title, date,
#                                                      dateOfIssue, abstract, detail,
#                                                      imagePath, imageCaption,
#                                                      imageSource, imgDates, id, type
#   bundesrat_stimmverteilung          one base page: list.item with title ("-"),
#                                                      imageCaption, imagePath, date,
#                                                      dateOfIssue, detail, abstract
#
# The fields detail, bodyText and topdetail carry HTML and stay out of the
# templates.
#
# Two answers hold more than the templates show: the session data of the
# current session (list.sitzung, list.stand, list.header, list.title) and the
# header of the compact plenary (list.header, a hash with titel1, titel2,
# titel3, url) stay in the answer and are not rendered.
#
# The template of an endpoint lives in share/templates/{lang}/{endpoint}.yml.
# The loader of the formatter reads .yml only, so the .yaml placeholders of
# these endpoints were ignored and the CLI answered with a raw YAML dump.
#
# Offline: nothing is fetched, the measured answers are written into the test
# as Perl data structures.

my @LANGS = qw(de en fr es it nl pl);

# The fields of a record are written as the path from the root of the answer
# (list.item.title), a table reads its rows from the extract path. The names
# are the ones the API delivers, they are not translated.
my %ENDPOINTS = (
    bundesrat_plenum_kompakt => {
        type    => 'table',
        extract => 'list.tops.top',
        fields  => [qw(nr title subtop)],
        names   => [qw(nr title subtop)],
    },
    bundesrat_plenum_aktuelle_sitzung => {
        type    => 'table',
        extract => 'list.top',
        fields  => [qw(toptitle topheader topdrucksache topurl)],
        names   => [qw(toptitle topheader topdrucksache topurl)],
    },
    bundesrat_plenum_chronologisch => {
        type    => 'record',
        extract => undef,
        fields  => [qw(list.title list.header)],
        names   => [qw(title header)],
    },
    bundesrat_plenum_naechste_sitzungen => {
        type    => 'record',
        extract => undef,
        fields  => [qw(list.item.title list.item.date list.item.dateOfIssue list.item.abstract)],
        names   => [qw(title date dateOfIssue abstract)],
    },
    bundesrat_stimmverteilung => {
        type    => 'record',
        extract => undef,
        fields  => [qw(list.item.imageCaption list.item.imagePath list.item.date list.item.dateOfIssue)],
        names   => [qw(imageCaption imagePath date dateOfIssue)],
    },
);

# The measured answers of the endpoints that are rendered below.
my %ANSWER = (
    bundesrat_plenum_kompakt => {
        list => {
            header => {
                titel1   => 'Ausgewählte Tagesordnungspunkte',
                titel2   => '1069. Sitzung des Bundesrates',
                titel3   => 'am Freitag, den 16. Oktober 2026, 09:30 Uhr',
                titelAlt => 'Ausgewählte Tagesordnungspunkte der 1069. Sitzung am 16.10.2026',
                url      => 'https://www.bundesrat.de/DE/plenum/bundesrat-kompakt/26/1069/1069-pk.html',
            },
            tops => {
                top => [
                    {
                        nr        => 'TOP 1',
                        title     => 'Präsidentschaftswechsel',
                        filter    => 'Personalien',
                        bvgtext   => '',
                        bvgurl    => '',
                        imagePath => 'https://www.bundesrat.de/SharedDocs/bilder/plenumkompakt/2026/1069/wuest.jpg?__blob=normal&v=5',
                        imageDate => '09.10.2026 14:29',
                        subtop    => [
                            {
                                name   => 'Beschluss',
                                title  => 'Hendrik Wüst wird neuer Präsident des Bundesrates',
                                type   => 'webview',
                                detail => '<h3>Hendrik Wüst neuer Bundesratspräsident</h3>',
                            },
                        ],
                    },
                    {
                        nr        => 'TOP 9',
                        title     => 'Gemeinschädlicher Hausfriedensbruch',
                        filter    => 'Landesinitiativen',
                        bvgtext   => '',
                        bvgurl    => '',
                        imagePath => '',
                        imageDate => '',
                        subtop    => {
                            name   => 'Beschluss',
                            title  => 'Gemeinschädlicher Hausfriedensbruch',
                            type   => 'webview',
                            detail => '<h3>Gemeinschädlicher Hausfriedensbruch</h3>',
                        },
                    },
                ],
            },
        },
    },
    bundesrat_plenum_aktuelle_sitzung => {
        list => {
            title  => '1069. Sitzung des Bundesrates | Tagesordnung Entwurf',
            header => 'am Freitag, dem 16. Oktober 2026, 9:30 Uhr',
            sitzung => '1069. Sitzung des Bundesrates',
            stand   => 'Stand: 16.10.2026, 12:30 Uhr',
            top    => [
                {
                    toptitle      => 'TOP b',
                    topheader     => 'Vorschlag für einen Beschluss des Europäischen Parlaments und des Rates zur Erneuerung einer Aktion der Europäischen Union für die "Kulturhauptstädte Europas" im Zeitraum 2034 bis 2047 und zur Aufhebung des Beschlusses Nr. 445/2014/EU',
                    topdrucksache => 'Drucksache 529/26',
                    topurl        => 'https://www.bundesrat.de/SharedDocs/TO/1069/tagesordnung-1069.html#top-1',
                    linkedtop     => '',
                    topdetail     => '<div class="tabinfo"><h3>b</h3></div>',
                },
                {
                    toptitle      => 'TOP 1',
                    topheader     => 'Wahl des Präsidiums',
                    topdrucksache => 'Drucksache 528/26',
                    topurl        => 'https://www.bundesrat.de/SharedDocs/TO/1069/tagesordnung-1069.html#top-2',
                    linkedtop     => '',
                    topdetail     => '<div class="tabinfo"><h3>1</h3></div>',
                },
            ],
        },
    },
    bundesrat_plenum_chronologisch => {
        list => {
            title  => '1069. Sitzung des Bundesrates',
            header => 'am Freitag, dem 16. Oktober 2026, 9:30 Uhr',
        },
    },
    bundesrat_plenum_naechste_sitzungen => {
        list => {
            item => {
                title       => 'Anstehende Plenarsitzungen',
                date        => '29.09.2026 11:49',
                dateOfIssue => '08.09.2026 00:00',
                abstract    => 'Der Bundesrat tritt ca. 10 Mal im Jahr im Abstand von drei bis vier Wochen zusammen.',
                detail      => '<div class="header"><h1>Anstehende Plenarsitzungen</h1></div>',
                imagePath   => '',
                imageCaption => '',
                imageSource => '',
                imgDates    => '',
                id          => '/BR/iOS/SharedDocs/3_Plenum/plenum_naechsteSitzungen',
                type        => 'Basepage',
            },
        },
    },
    bundesrat_stimmverteilung => {
        list => {
            item => {
                title        => '-',
                imageCaption => 'Zusammensetzung des Bundesrates',
                imagePath    => 'https://www.bundesrat.de/SharedDocs/bilder/DE/artikel/rubrik-bundesrat/zusammensetzung.jpg?__blob=normal&v=103',
                date         => '09.09.2026 15:48',
                dateOfIssue  => '09.09.2026 12:00',
                abstract     => '',
                detail       => '<div class="header"><h1>-</h1></div>',
                imageDate    => '30.09.2026 11:34',
                imageSource  => '',
                imgDates     => '30.09.2026 11:34',
                id           => '/BR/iOS/v3/06_Stimmen/stimmverteilung',
                type         => 'Basepage',
            },
        },
    },
);

my $templates_dir = File::Spec->catdir($FindBin::Bin, '..', 'share', 'templates');
my $strings_dir   = File::Spec->catdir($FindBin::Bin, '..', 'share', 'strings');

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

        is($template->{extract}, $spec->{extract},
            $spec->{extract}
            ? "$endpoint/$lang: the template reads $spec->{extract}"
            : "$endpoint/$lang: the template reads no path");

        my $empty = $template->{empty};
        ok(defined $empty && length $empty,
            "$endpoint/$lang: the template has an empty message");

        my $list = $spec->{type} eq 'table' ? $template->{columns} : $template->{fields};
        $list ||= [];
        is_deeply(
            [map { ref $_ eq 'HASH' ? $_->{field} : undef } @$list],
            $spec->{fields},
            "$endpoint/$lang: the fields are " . join(', ', @{ $spec->{names} })
        );

        # The names of the fields are the ones the API delivers.
        is_deeply(
            [map { my $f = ref $_ eq 'HASH' ? $_->{field} : ''; (split /\./, $f)[-1] } @$list],
            $spec->{names},
            "$endpoint/$lang: the fields keep the names of the API"
        );

        # The headers and the labels are translated, the field names are not.
        $text{$lang} = join '|', sort map { ref $_ eq 'HASH' ? ($_->{header} // $_->{label} // '') : '' } @$list;
    }

    for my $lang (grep { $_ ne 'de' } @LANGS) {
        isnt($text{$lang}, $text{de},
            "$endpoint/$lang: the template is translated, not copied from the German one");
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

# The cells of a rendered line: the columns are separated by two spaces, the
# value of a cell is padded to the width of the column.
sub cells {
    my ($line) = @_;
    return [map { my $c = $_; $c =~ s/\A\s+//; $c =~ s/\s+\z//; $c } split /\s{2,}/, $line];
}

# The output as one line: a value that is wrapped is broken into lines.
sub one_line {
    my ($text) = @_;
    $text =~ s/\s+/ /g;
    $text =~ s/\A //;
    $text =~ s/ \z//;
    return $text;
}

# The value of a field of the answer, read along its path.
sub value_of {
    my ($answer, $path) = @_;
    my $value = $answer;
    for my $key (split /\./, $path) {
        return undef unless ref $value eq 'HASH';
        $value = $value->{$key};
        return undef unless defined $value;
    }
    return $value;
}

# An answer whose path holds an empty list.
sub empty_answer {
    my ($path) = @_;
    my $data = [];
    for my $key (reverse split /\./, $path) {
        $data = { $key => $data };
    }
    return $data;
}

for my $endpoint (qw(bundesrat_plenum_kompakt bundesrat_plenum_aktuelle_sitzung)) {
    my $spec  = $ENDPOINTS{$endpoint};
    my @rows  = @{ value_of($ANSWER{$endpoint}, $spec->{extract}) || [] };

    for my $lang (qw(de en)) {
        my $file     = File::Spec->catfile($templates_dir, $lang, "$endpoint.yml");
        my $template = -f $file ? LoadFile($file) : {};
        my $fmt      = formatter($lang);
        my $out      = $fmt->format_output($ANSWER{$endpoint}, $endpoint, 'template');

        unlike($out, qr/^\s*-\s/m, "$endpoint/$lang: the answer is no YAML dump");
        like($out, qr/^-{3,}$/m, "$endpoint/$lang: the answer is a table");

        my @headers = $template->{columns}
            ? map { $_->{header} // uc($_->{field}) } @{ $template->{columns} }
            : ();
        my @lines = split /\n/, $out;
        is_deeply(cells($lines[0] // ''), \@headers,
            "$endpoint/$lang: the table carries the headers of the template");

        # Every value of the answer is in the output, no field stays empty.
        # The subtop of the compact plenary is a structure (a hash or a list of
        # hashes); the formatter writes no structure into a cell, so the agenda
        # is read from the number and the title.
        my @shown = grep { $_ ne 'subtop' } @{ $spec->{fields} };
        for my $i (0 .. $#rows) {
            for my $field (@shown) {
                my $value = $rows[$i]{$field};
                ok(defined $value && length $value,
                    "$endpoint/$lang: row " . ($i + 1) . " has a $field");

                # A value that is longer than the column is wrapped by the
                # formatter, so the values of the other columns stand between
                # the parts of the value. They are taken out of the text
                # before the value is looked for.
                my @others = map { $rows[$i]{$_} }
                             grep { $_ ne $field } @shown;
                my $text = one_line($out);
                for my $other (@others) {
                    next unless defined $other && length $other;
                    $text =~ s/\Q$other\E//g;
                }
                $text = one_line($text);
                like($text, qr/\Q$value\E/,
                    "$endpoint/$lang: row " . ($i + 1) . " shows its $field");
            }
        }

        # The empty message of the template is used when the answer is empty
        my $empty_answer = empty_answer($spec->{extract});
        my $empty_out = $fmt->format_output($empty_answer, $endpoint, 'template');
        is($empty_out, ($template->{empty} // '') . "\n",
            "$endpoint/$lang: the empty message of the template is used");
    }
}

# --- the measured answers are rendered as a record --------------------------
for my $endpoint (qw(bundesrat_plenum_chronologisch
                     bundesrat_plenum_naechste_sitzungen
                     bundesrat_stimmverteilung)) {
    for my $lang (qw(de en)) {
        my $file     = File::Spec->catfile($templates_dir, $lang, "$endpoint.yml");
        my $template = -f $file ? LoadFile($file) : {};
        my $fmt      = formatter($lang);
        my $out      = $fmt->format_output($ANSWER{$endpoint}, $endpoint, 'template');

        unlike($out, qr/^\s*-\s/m, "$endpoint/$lang: the answer is no YAML dump");

        my @fields = $template->{fields} ? @{ $template->{fields} } : ();
        for my $i (0 .. $#fields) {
            my $field = $fields[$i]{field};
            my $label = $fields[$i]{label} // $field;
            my $value = value_of($ANSWER{$endpoint}, $field);

            ok(defined $value && length $value,
                "$endpoint/$lang: the answer has a $field");
            like($out, qr/^\s*\Q$label\E\s+\Q$value\E\s*$/m,
                "$endpoint/$lang: the record shows its $field");
        }
    }
}

done_testing;
