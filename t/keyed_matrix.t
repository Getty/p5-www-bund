#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);

use WWW::Bund::CLI::Formatter;

# Offline guard for the keyed_matrix template type: data that arrives as a
# header row with numbered or positional rows (the format of the
# Umweltbundesamt API).
#
# The templates of the test cases are written into a temporary directory and
# loaded through the real _load_template, so the test walks the same path as
# the CLI does.

my $strings_dir   = File::Spec->catdir($FindBin::Bin, '..', 'share', 'strings');
my $templates_dir = File::Spec->catdir($FindBin::Bin, '..', 'share', 'templates');

my $tmp = tempdir(CLEANUP => 1);
mkdir File::Spec->catdir($tmp, 'de') or die "cannot create $tmp/de: $!";

sub write_template {
    my ($name, $body) = @_;
    my $path = File::Spec->catfile($tmp, 'de', "$name.yml");
    open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path: $!";
    print $fh $body;
    close $fh or die "cannot close $path: $!";
    return $path;
}

sub formatter {
    my (%opts) = @_;
    return WWW::Bund::CLI::Formatter->new(
        templates_dir => $opts{templates_dir} // $tmp,
        strings_dir   => $strings_dir,
        lang          => $opts{lang} // 'de',
    );
}

my $fmt = formatter();

# --- Variante A: numerically keyed rows at the top level --------------------
{
    write_template('matrix_a', <<'TPL');
type: keyed_matrix
row_key: true
empty: "nichts gefunden"
TPL

    my $data = {
        count   => 3,
        indices => ['component id','component code','component name'],
        '1'     => ['1','PM10','Particulate matter'],
        '9'     => ['9','CO','Carbon monoxide'],
        '10'    => ['10','O3','Ozone'],
    };

    my $out = $fmt->format_output($data, 'matrix_a', 'template');

    like($out, qr/component id\s+component code\s+component name/,
        'A: the header row comes from the API');
    like($out, qr/^1\s+1\s+PM10\s+Particulate matter/m,
        'A: the first row shows its values');
    like($out, qr/^10\s+10\s+O3\s+Ozone/m,
        'A: the tenth row shows its values');

    my $pos9  = index($out, 'Carbon monoxide');
    my $pos10 = index($out, 'Ozone');
    ok($pos9 >= 0 && $pos10 > $pos9,
        'A: the rows are sorted numerically ("9" before "10")');

    unlike($out, qr/count/, 'A: keys that are no numbers are no rows');
}

# --- Variante B: the rows live under "data" --------------------------------
{
    write_template('matrix_b', <<'TPL');
type: keyed_matrix
rows: data
empty: "nichts gefunden"
TPL

    my $data = {
        indices => ['network id','network code','network name'],
        data    => {
            '1' => ['1','BW','Baden-Württemberg'],
            '2' => ['2','BE','Berlin'],
        },
        count   => 2,
    };

    my $out = $fmt->format_output($data, 'matrix_b', 'template');

    like($out, qr/network id\s+network code\s+network name/,
        'B: the header row comes from the API');
    like($out, qr/^1\s+1\s+BW\s+Baden-Württemberg/m,
        'B: the first row shows its values');
    like($out, qr/^2\s+2\s+BE\s+Berlin/m,
        'B: the second row shows its values');
}

# --- Variante C: the header is a hash and names the key column --------------
{
    write_template('matrix_c', <<'TPL');
type: keyed_matrix
rows: data
empty: "nichts gefunden"
TPL

    my $data = {
        indices => {
            'station id' => ['limit date start min (CET)','limit date start max (CET)'],
        },
        data => {
            '7'  => ['2016-01-01 00:00:00','2021-01-18 12:00:00'],
            '21' => ['2016-02-01 00:00:00','2021-02-18 12:00:00'],
        },
    };

    my $out = $fmt->format_output($data, 'matrix_c', 'template');

    like($out, qr/^station id\s+limit date start min/m,
        'C: the key of the header names the key column');
    like($out, qr/^7\s+2016-01-01 00:00:00\s+2021-01-18 12:00:00/m,
        'C: the first row shows its values');
    like($out, qr/^21\s+2016-02-01/m,
        'C: the second row shows its values');
}

# --- Variante D: the rows are a list of rows, they are numbered ------------
{
    write_template('matrix_d', <<'TPL');
type: keyed_matrix
rows: data
empty: "nichts gefunden"
TPL

    my $data = {
        indices => ['station id','day_first','day_recent'],
        data    => [
            ['21','2023-01-24','2023-12-31'],
            ['22','2023-02-01','2023-12-30'],
        ],
    };

    my $out = $fmt->format_output($data, 'matrix_d', 'template');

    like($out, qr/station id\s+day_first\s+day_recent/,
        'D: the header row comes from the API');
    like($out, qr/^1\s+21\s+2023-01-24\s+2023-12-31/m,
        'D: the rows are numbered from 1');
    like($out, qr/^2\s+22\s+2023-02-01/m,
        'D: the second row shows its values');
}

# --- Variante E: two levels deep, the key chain is kept ---------------------
{
    write_template('matrix_e', <<'TPL');
type: keyed_matrix
header: indices.data.station id.date start
rows: data
empty: "nichts gefunden"
TPL

    my $data = {
        indices => {
            data => {
                'station id' => {
                    'date start' => ['component id','scope id','value','date end','index'],
                },
            },
        },
        data => {
            '21' => {
                '2024-01-01 06:00:00' => [ 9, 6, 19, '2024-01-01 07:00:00', '7' ],
                '2024-01-01 07:00:00' => [ 9, 6, 21, '2024-01-01 08:00:00', '7' ],
            },
        },
    };

    my $out = $fmt->format_output($data, 'matrix_e', 'template');

    like($out, qr/component id\s+scope id\s+value\s+date end\s+index/,
        'E: the header comes from the deep path');
    like($out, qr{^21 / 2024-01-01 06:00:00\s+9\s+6\s+19\s+2024-01-01 07:00:00\s+7}m,
        'E: the key chain is joined with a slash');
    like($out, qr{^21 / 2024-01-01 07:00:00\s+9\s+6\s+21}m,
        'E: the second row shows its values');
}

# --- No row at all ----------------------------------------------------------
{
    my $data = { count => 0, indices => ['component id'] };

    my $out = $fmt->format_output($data, 'matrix_a', 'template');

    is($out, "nichts gefunden\n", 'without a row the empty message is shown');
}

# --- No header: the raw data is shown ---------------------------------------
{
    my $data = { count => 12, '1' => ['a','b'] };

    my $out = $fmt->format_output($data, 'matrix_a', 'template');

    like($out, qr/count: 12/, 'without a header the data is dumped as YAML');
    unlike($out, qr/^-{4,}$/m, 'without a header there is no table');
}

# --- A nested structure in a cell becomes compact JSON ----------------------
{
    my $data = {
        indices => ['name','values','more'],
        '1'     => ['first', [1,2,3], {key => 'value'}],
    };

    my $out = $fmt->format_output($data, 'matrix_a', 'template');

    like($out, qr/\Q[1,2,3]\E/, 'a nested list becomes compact JSON in the cell');
    like($out, qr/\Q{"key":"value"}\E/, 'a nested hash becomes compact JSON in the cell');
}

# --- A boolean in a cell is translated --------------------------------------
{
    my $data = { indices => ['flag'], '1' => ['true'] };

    my $out = $fmt->format_output($data, 'matrix_a', 'template');

    like($out, qr/^1\s+ja/m, 'a boolean is translated (de)');
}

# --- The columns of the template win over the ones of the API ---------------
{
    write_template('matrix_f', <<'TPL');
type: keyed_matrix
row_key: false
columns:
  - field: "1"
    header: "Zweite Spalte"
    width: 20
  - field: "0"
    header: "Erste Spalte"
TPL

    my $data = { indices => ['first','second'], '1' => ['eins','zwei'] };

    my $out = $fmt->format_output($data, 'matrix_f', 'template');

    like($out, qr/Zweite Spalte\s+Erste Spalte/,
        'the columns of the template decide the order');
    like($out, qr/^zwei\s+eins/m, 'the field names are the positions in the row');
    unlike($out, qr/^first\s+second/m, 'the header of the API is not used');
}

# --- More than 100 rows get a hint ------------------------------------------
{
    my $data = {
        indices => ['component id'],
        map { $_ => [ $_ ] } 1 .. 120,
    };

    my $out = $fmt->format_output($data, 'matrix_a', 'template');

    like($out, qr/\.\.\. und 20 weitere Zeilen/,
        'more than 100 rows get a hint like in the type table');
}

# --- The templates of the distribution render the formats -------------------
{
    my $real = formatter(templates_dir => $templates_dir);

    my %shapes = (
        luftqualitaet_components => {
            indices => ['component id','component name'],
            '1'     => ['1','Particulate matter'],
        },
        luftqualitaet_networks => {
            indices => ['network id','network name'],
            data    => { '1' => ['1','UBA'] },
        },
        luftqualitaet_airquality_limits => {
            indices => { 'station id' => ['limit date start min (CET)'] },
            data    => { '7' => ['2016-01-01 00:00:00'] },
        },
        luftqualitaet_annualbalances => {
            indices => ['station id','day_first'],
            data    => [ ['21','2023-01-24'] ],
        },
        luftqualitaet_measures => {
            indices => { data => { 'station id' => { 'date start' => ['component id','value'] } } },
            data    => { '21' => { '2024-01-01 06:00:00' => [ 9, 19 ] } },
        },
    );

    for my $endpoint (sort keys %shapes) {
        my $out = $real->format_output($shapes{$endpoint}, $endpoint, 'template');
        like($out, qr/^-+$/m, "$endpoint renders a table");
        unlike($out, qr/^---$/m, "$endpoint does not fall back to the YAML dump");
    }
}

done_testing;
