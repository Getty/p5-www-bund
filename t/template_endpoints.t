use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use FindBin;
use YAML::PP qw(LoadFile);

# Every template of the distribution belongs to an endpoint of the endpoint
# catalog. The formatter looks the template up by the name of the endpoint
# (share/templates/{lang}/{endpoint}.yml), so a template that belongs to no
# endpoint is never loaded: it is a leftover of a renamed endpoint or of an
# API that has no endpoint at all.
#
# The test reads the data of the distribution, not the code. It can be run
# against a tree with an old state of share/ and names the dead templates.
#
# The other direction - every endpoint has a template - is not true and is
# not checked here: some endpoints show the answer of the API as it is.

my $share = File::Spec->catdir($FindBin::Bin, '..', 'share');

my @languages = qw(de en fr es it nl pl);

my $endpoints = LoadFile(File::Spec->catfile($share, 'endpoints.yml'));
my %endpoint = map { $_->{name} => 1 } @$endpoints;

sub template_names {
    my ($language) = @_;
    my $dir = File::Spec->catdir($share, 'templates', $language);
    opendir my $dh, $dir or die "cannot read $dir: $!";
    my @names = sort map { s/\.ya?ml\z//r } grep { /\.ya?ml\z/ } readdir $dh;
    closedir $dh;
    return @names;
}

my %by_language;

for my $language (@languages) {
    my $dir = File::Spec->catdir($share, 'templates', $language);
    ok(-d $dir, "the language folder share/templates/$language is there");

    my @names = template_names($language);
    $by_language{$language} = \@names;

    my @dead = grep { !$endpoint{$_} } @names;

    ok( scalar @dead == 0,
        "every template in share/templates/$language belongs to an endpoint of share/endpoints.yml" )
        or diag( 'template without an endpoint: ' . join( ', ', @dead ) );

    # Every dead template is named on a line of its own, so the failure shows
    # what has to go.
    ok( 0, "the template $language/$_.yml belongs to an endpoint of share/endpoints.yml" )
        for @dead;
}

# All seven languages carry the same templates.
my $first = $languages[0];
for my $language ( @languages[ 1 .. $#languages ] ) {
    is_deeply( $by_language{$language}, $by_language{$first},
        "share/templates/$language carries the same templates as share/templates/$first" );
}

done_testing;
