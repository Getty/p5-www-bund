#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);

use WWW::Bund::CLI::Formatter;

my $templates_dir = File::Spec->catdir($FindBin::Bin, '..', 'share', 'templates');
my $strings_dir   = File::Spec->catdir($FindBin::Bin, '..', 'share', 'strings');

my @languages = qw(de en fr es it nl pl);

# Helper to create formatter
sub make_fmt {
    my (%opts) = @_;
    WWW::Bund::CLI::Formatter->new(
        templates_dir => $opts{templates_dir} // $templates_dir,
        strings_dir   => $opts{strings_dir}   // $strings_dir,
        lang          => $opts{lang}          // 'de',
    );
}

# A templates directory of its own, with an empty German folder
sub make_templates_dir {
    my $dir = tempdir(CLEANUP => 1);
    mkdir File::Spec->catdir($dir, 'de') or die "cannot create the language folder: $!";
    return $dir;
}

# A template with a table and a header of its own
sub write_template {
    my ($path, $header) = @_;
    open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path: $!";
    print $fh "type: table\ncolumns:\n  - field: name\n    header: $header\n";
    close $fh;
}

# --- a template that is named .yaml is found ---
{
    my $dir = make_templates_dir();
    write_template(File::Spec->catfile($dir, 'de', 'demo.yaml'), 'VON-YAML');

    my $fmt = make_fmt(templates_dir => $dir);
    my $out = $fmt->format_output([{ name => 'Alpha' }], 'demo', 'template');

    like($out, qr/VON-YAML/, 'a template that is named .yaml is found');
    like($out, qr/Alpha/, 'the answer is rendered with the template');
    unlike($out, qr/name: Alpha/, 'the answer is not the YAML fallback');
}

# --- the template that is named .yml wins ---
{
    my $dir = make_templates_dir();
    write_template(File::Spec->catfile($dir, 'de', 'demo.yml'),   'VON-YML');
    write_template(File::Spec->catfile($dir, 'de', 'demo.yaml'), 'VON-YAML');

    my $fmt = make_fmt(templates_dir => $dir);
    my $out = $fmt->format_output([{ name => 'Alpha' }], 'demo', 'template');

    like($out, qr/VON-YML/, 'the template that is named .yml wins');
    unlike($out, qr/VON-YAML/, 'the template that is named .yaml is not used');
}

# --- without a template the answer is the YAML fallback ---
{
    my $dir = make_templates_dir();

    my $fmt = make_fmt(templates_dir => $dir);
    my $out = $fmt->format_output({ some => 'data' }, 'demo', 'template');

    like($out, qr/some: data/, 'without a template the answer is the YAML fallback');
    unlike($out, qr/Keine Daten/, 'the fallback does not claim that there is no data');
}

# --- in the shipped templates there is no file that is named .yaml ---
{
    for my $language (@languages) {
        my $dir = File::Spec->catdir($templates_dir, $language);
        ok(-d $dir, "the language folder share/templates/$language is there");

        opendir my $dh, $dir or die "cannot read $dir: $!";
        my @yaml = grep { /\.yaml\z/ } readdir $dh;
        closedir $dh;

        is(scalar @yaml, 0, "no template that is named .yaml in share/templates/$language");
    }
}

done_testing;
