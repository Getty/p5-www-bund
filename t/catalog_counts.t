use strict;
use warnings;
use Test::More;
use YAML::PP qw(LoadFile);
use File::Spec;
use FindBin;

# The counts the documentation gives for the catalog have to match the data
# files that are shipped: share/registry.yml is the source for the number of
# registered APIs, share/endpoints.yml for the number of endpoints and for the
# number of APIs that have endpoints.

my $root = File::Spec->catdir( $FindBin::Bin, '..' );
my $share = File::Spec->catdir( $root, 'share' );

my $registry = LoadFile( File::Spec->catfile( $share, 'registry.yml' ) );
my $endpoints = LoadFile( File::Spec->catfile( $share, 'endpoints.yml' ) );

my %api_ids = map { $_->{id} => 1 } grep { $_->{id} } @$registry;
my %endpoint_names = map { $_->{name} => 1 } grep { $_->{name} } @$endpoints;
my %apis_with_endpoints = map { $_->{api} => 1 } grep { $_->{api} } @$endpoints;

my $api_count = scalar keys %api_ids;
my $endpoint_count = scalar keys %endpoint_names;
my $with_endpoints = scalar keys %apis_with_endpoints;
my $without_endpoints = $api_count - $with_endpoints;

ok( $api_count > 0, 'registry.yml holds APIs' );
ok( $endpoint_count > 0, 'endpoints.yml holds endpoints' );

sub read_file {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot read $file: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}

sub numbers_in {
    my ($text) = @_;
    my %numbers;
    while ( $text =~ /(\d+)/g ) { $numbers{$1} = 1 }
    return \%numbers;
}

sub check_counts {
    my ( $text, $counts, $where ) = @_;
    my $found = numbers_in($text);
    for my $count ( @{$counts} ) {
        ok( $found->{$count}, "$where mentions the number $count" );
    }
}

# Registry.pm describes the catalog in the DESCRIPTION of the class.
{
    my $file = File::Spec->catfile( $root, 'lib', 'WWW', 'Bund', 'Registry.pm' );
    my $text = read_file($file);

    my ($description) = $text =~ /^=head1[ ]DESCRIPTION\s*\n(.*?)^=cut/ms;
    ok( $description, 'Registry.pm has a DESCRIPTION section' );

    check_counts(
        $description,
        [ $api_count, $endpoint_count, $with_endpoints, $without_endpoints ],
        'the DESCRIPTION of Registry.pm'
    );
    like( $description, qr/\Qregistry.yml\E/,
        'the DESCRIPTION of Registry.pm names registry.yml' );
    like( $description, qr/\Qendpoints.yml\E/,
        'the DESCRIPTION of Registry.pm names endpoints.yml' );
}

# README.md describes the catalog in the section about the data files. The file
# is not part of the built distribution, so the check is skipped there.
{
    my $file = File::Spec->catfile( $root, 'README.md' );
    SKIP: {
        skip 'README.md is not shipped in the built distribution', 7
            unless -e $file;

        my $text = read_file($file);

        my ($section) = $text =~ /^###[ ]Data Files\s*\n(.*?)^##[ ]/ms;
        ok( $section, 'README.md has a Data Files section' );

        check_counts(
            $section,
            [ $api_count, $endpoint_count, $with_endpoints, $without_endpoints ],
            'the Data Files section of README.md'
        );
        like( $section, qr/\Qregistry.yml\E/,
            'the Data Files section of README.md names registry.yml' );
        like( $section, qr/\Qendpoints.yml\E/,
            'the Data Files section of README.md names endpoints.yml' );
    }
}

done_testing;
