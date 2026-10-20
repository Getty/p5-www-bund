#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use FindBin;
use Test::More;

my $cpanfile = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'cpanfile' );

plan skip_all => 'cpanfile is not part of the distribution' unless -f $cpanfile;

# The cpanfile is what the installer reads. A library the code loads but the
# cpanfile does not name is not missing while the distribution is built, it is
# missing when the library is loaded on a machine where the module is not
# installed yet. The suite reads the cpanfile, so that gap fails here.

open my $fh, '<', $cpanfile or die "cannot read $cpanfile: $!";
my %requires;    # phase => { module => 1 }
my %order;       # phase => [ modules in the order of the cpanfile ]
my $phase = 'runtime';
while ( my $line = <$fh> ) {
    if ( $line =~ /^\s*on\s+(\w+)\s*=>\s*sub\s*\{/ ) {
        $phase = $1;
        next;
    }
    next unless $line =~ /^\s*requires\s+'([^']+)'/;
    $requires{$phase}{$1} = 1;
    push @{ $order{$phase} }, $1;
}
close $fh;

my $runtime = $requires{runtime} || {};
my $test    = $requires{test}    || {};

# The libraries the code loads, per phase. The first name of a requirement is
# the module, the names behind it are the distributions that carry it: where
# module and distribution run apart, the distribution counts and the cpanfile
# may name either of them.
my @runtime = (
    [qw( File::ShareDir::ProjectDistDir File::ShareDir )],
    [qw( HTTP::Request HTTP::Message )],
    [qw( JSON::MaybeXS )],
    [qw( LWP::Protocol::https )],
    [qw( LWP::UserAgent )],
    [qw( Log::Any Log::Any::Adapter )],
    [qw( Moo Moo::Role )],
    [qw( MooX::Cmd )],
    [qw( MooX::Options )],
    [qw( URI::Escape URI )],
    [qw( XML::Twig )],
    [qw( YAML::PP )],
    [qw( namespace::clean )],
);

my @test = (
    [qw( HTTP::Response HTTP::Message HTTP::Request )],
    [qw( JSON::MaybeXS )],
    [qw( Log::Any::Adapter Log::Any )],
    [qw( Moo )],
    [qw( Test::Exception )],
    [qw( Test::More )],
    [qw( YAML::PP )],
);

# A runtime prerequisite has to stand in the runtime phase: an entry in the
# test phase alone is not installed when the distribution is applied. A test
# prerequisite may stand in the test phase or in the runtime phase, because the
# runtime phase is installed in any case.

for my $requirement ( @runtime ) {
    ok( scalar( grep { $runtime->{$_} } @$requirement ),
        "$requirement->[0] is a declared prerequisite" );
}

for my $requirement ( @test ) {
    ok( scalar( grep { $runtime->{$_} || $test->{$_} } @$requirement ),
        "$requirement->[0] is a declared prerequisite for the tests" );
}

# The cpanfile lists its prerequisites alphabetically, case-insensitively:
# otherwise LWP::Protocol::https would stand before Log::Any.
sub sort_modules { sort { lc $a cmp lc $b } @_ }

is_deeply( $order{runtime}, [ sort_modules( @{ $order{runtime} || [] } ) ],
    'the runtime prerequisites are listed alphabetically' );
is_deeply( $order{test}, [ sort_modules( @{ $order{test} || [] } ) ],
    'the test prerequisites are listed alphabetically' );

done_testing;
