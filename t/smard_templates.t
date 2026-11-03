#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use YAML::PP qw(LoadFile);

use WWW::Bund::CLI::Formatter;

# Offline test of the templates of the three SMARD endpoints.
#
# The shapes of the answers were measured on 2026-10-20 (the answers are
# written into the test as Perl data structures, nothing is fetched):
#
#   smard_indices     {"timestamps":[1419807600000,1792360800000,...]}
#                     a list of timestamps in milliseconds
#   smard_timeseries  {"meta_data":{...},"series":[[1792360800000,10733.5],
#                     [1792361700000,10655.25],...]}
#                     the rows are positional pairs (timestamp, value)
#   smard_table       {"meta_data":{...},"series":[{"values":[{"timestamp":
#                     1419807600000,"versions":[{"value":12,"name":"x"}]}]}]}
#                     the rows live under series[0].values[], one level deeper
#                     than the OpenAPI spec describes
#
# Two extensions of the formatter belong to the endpoints:
#
#   - the type keyed_matrix takes the columns from the template when the
#     answer has no header row (the SMARD answers have none)
#   - a cell of the type table that holds a nested structure shows the value
#     as compact JSON instead of leaving the cell empty
#
# The template of an endpoint lives in share/templates/{lang}/{endpoint}.yml.
# The .yaml placeholders of these endpoints only reported that there was no
# data; they are removed, so the endpoints render with their own .yml template.

my @LANGS = qw(de en fr es it nl pl);

# The type of the template, the path it reads from the answer and the fields
# of its columns. The names of the fields are the ones the API delivers, they
# are not translated.
my %ENDPOINTS = (
    smard_indices => {
        type    => 'list',
        extract => 'timestamps',
        fields  => [],
    },
    smard_timeseries => {
        type    => 'keyed_matrix',
        extract => undef,
        rows    => 'series',
        row_key => 0,
        fields  => ['0', '1'],
    },
    smard_table => {
        type    => 'table',
        extract => 'series.0.values',
        fields  => [qw(timestamp versions)],
    },
);

# The measured answers of the endpoints.
my %ANSWER = (
    smard_indices => {
        timestamps => [ 1419807600000, 1792360800000, 1792361700000 ],
    },
    smard_timeseries => {
        meta_data => { version => 1, created => 1789000000 },
        series    => [
            [ 1792360800000, 10733.5 ],
            [ 1792361700000, 10655.25 ],
        ],
    },
    smard_table => {
        meta_data => { version => 1, created => 1789000000 },
        series    => [
            {
                values => [
                    {
                        timestamp => 1419807600000,
                        versions => [ { value => 12, name => 'x' } ],
                    },
                ],
            },
        ],
    },
);

my $templates_dir = File::Spec->catdir($FindBin::Bin, '..', 'share', 'templates');
my $strings_dir   = File::Spec->catdir($FindBin::Bin, '..', 'share', 'strings');

sub formatter {
    my ($lang, $dir) = @_;
    return WWW::Bund::CLI::Formatter->new(
        templates_dir => $dir // $templates_dir,
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

        if (exists $spec->{rows}) {
            is($template->{rows}, $spec->{rows},
                "$endpoint/$lang: the template reads the rows from $spec->{rows}");
            ok(!$template->{row_key},
                "$endpoint/$lang: the template shows no key column");
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

# --- the measured answers are rendered ---------------------------------------
{
    my $fmt = formatter('de');

    # smard_indices: a list of timestamps, one value per line
    my $out = $fmt->format_output($ANSWER{smard_indices}, 'smard_indices', 'template');

    unlike($out, qr/timestamps/, 'smard_indices: the answer is no YAML dump');
    for my $timestamp (@{ $ANSWER{smard_indices}{timestamps} }) {
        like($out, qr/^\Q$timestamp\E$/m,
            "smard_indices: the timestamp $timestamp is shown");
    }
}

{
    my $fmt = formatter('de');

    # smard_timeseries: the positional pairs become a table
    my $out = $fmt->format_output($ANSWER{smard_timeseries}, 'smard_timeseries', 'template');

    unlike($out, qr/series:/, 'smard_timeseries: the answer is no YAML dump');
    like($out, qr/^-{4,}$/m, 'smard_timeseries: the answer is a table');
    like($out, qr/^1792360800000\s+10733\.5\s*$/m,
        'smard_timeseries: the first row shows its timestamp and its value');
    like($out, qr/^1792361700000\s+10655\.25\s*$/m,
        'smard_timeseries: the second row shows its timestamp and its value');

    my @rows = grep { /\S/ && !/^-/ } split /\n/, $out;
    is(scalar @rows, 3, 'smard_timeseries: the table has a header and two rows');
}

{
    my $fmt = formatter('de');

    # smard_table: the rows live under series[0].values
    my $out = $fmt->format_output($ANSWER{smard_table}, 'smard_table', 'template');

    unlike($out, qr/values:/, 'smard_table: the answer is no YAML dump');
    like($out, qr/^-{4,}$/m, 'smard_table: the answer is a table');
    like($out, qr/^1419807600000\s+/m,
        'smard_table: the row shows its timestamp');
    like($out, qr/\Q[{"name":"x","value":12}]\E/,
        'smard_table: the versions are shown as JSON in the cell');
}

# --- the empty message of the template is used -------------------------------
{
    my $fmt = formatter('de');

    # An answer whose list at the path of the template is empty.
    my %EMPTY = (
        smard_indices    => { timestamps => [] },
        smard_timeseries => { series    => [] },
        smard_table      => { series    => [ { values => [] } ] },
    );

    for my $endpoint (sort keys %ENDPOINTS) {
        my $file     = File::Spec->catfile($templates_dir, 'de', "$endpoint.yml");
        my $template = LoadFile($file);
        my $empty    = $template->{empty} // '';
        my $out      = $fmt->format_output($EMPTY{$endpoint}, $endpoint, 'template');

        like($out, qr/\Q$empty\E/,
            "$endpoint: the empty message of the template is used");
    }
}

# --- the extension: a keyed_matrix without a header row ----------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    mkdir File::Spec->catdir($tmp, 'de') or die "cannot create $tmp/de: $!";

    my $path = File::Spec->catfile($tmp, 'de', 'matrix_no_header.yml');
    open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path: $!";
    print $fh <<'TPL';
type: keyed_matrix
rows: series
row_key: false
columns:
  - field: "0"
    header: Erste
  - field: "1"
    header: Zweite
empty: "nichts gefunden"
TPL
    close $fh or die "cannot close $path: $!";

    my $fmt  = formatter('de', $tmp);
    my $data = { series => [ [ 'a', 'b' ], [ 'c', 'd' ] ] };

    my $out = $fmt->format_output($data, 'matrix_no_header', 'template');

    unlike($out, qr/series:/, 'without a header row the answer is no YAML dump');
    like($out, qr/^Erste\s+Zweite\s*$/m, 'without a header row the columns of the template are the header');
    like($out, qr/^a\s+b\s*$/m, 'without a header row the first row shows its values');
    like($out, qr/^c\s+d\s*$/m, 'without a header row the second row shows its values');
}

# --- without a header row and without columns the raw data is shown ---------
{
    my $tmp = tempdir(CLEANUP => 1);
    mkdir File::Spec->catdir($tmp, 'de') or die "cannot create $tmp/de: $!";

    my $path = File::Spec->catfile($tmp, 'de', 'matrix_no_columns.yml');
    open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path: $!";
    print $fh <<'TPL';
type: keyed_matrix
rows: series
empty: "nichts gefunden"
TPL
    close $fh or die "cannot close $path: $!";

    my $fmt  = formatter('de', $tmp);
    my $data = { series => [ [ 'a', 'b' ] ] };

    my $out = $fmt->format_output($data, 'matrix_no_columns', 'template');

    like($out, qr/series:/, 'without a header row and without columns the data is dumped as YAML');
}

# --- the extension: a cell with a nested structure is not empty --------------
{
    my $tmp = tempdir(CLEANUP => 1);
    mkdir File::Spec->catdir($tmp, 'de') or die "cannot create $tmp/de: $!";

    my $path = File::Spec->catfile($tmp, 'de', 'table_nested.yml');
    open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path: $!";
    print $fh <<'TPL';
type: table
columns:
  - field: name
    header: Name
  - field: detail
    header: Detail
  - field: values
    header: Werte
empty: "nichts gefunden"
TPL
    close $fh or die "cannot close $path: $!";

    my $fmt  = formatter('de', $tmp);
    my $data = [
        { name => 'erste', detail => { key => 'value' }, values => [ 1, 2, 3 ] },
    ];

    my $out = $fmt->format_output($data, 'table_nested', 'template');

    like($out, qr/\Q{"key":"value"}\E/,
        'a nested hash in a cell is shown as JSON');
    like($out, qr/\Q[1,2,3]\E/,
        'a nested list in a cell is shown as JSON');
    unlike($out, qr/^\s*erste\s*$/m,
        'the cell with the nested values is not empty');
}

done_testing;
