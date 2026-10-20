use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use WWW::Bund::Registry;
use WWW::Bund::Caller;
use WWW::Bund::Auth;
use WWW::Bund::Cache;
use WWW::Bund::RateLimit;
use WWW::Bund::HTTPResponse;

# The Bundesrat endpoints of the website answer with the HTML page of the site
# unless the query parameter view=renderXml is sent. The body then starts with
# '<', the caller picks the XML parser and dies with
# "syntax error at line 1, column 0, byte 0". Measured 2026-10-20: with
# view=renderXml all ten endpoints answer with real XML.
#
# Offline: the endpoint data comes from share/endpoints.yml, the request goes
# to a MockIO. Nothing is fetched from the network.

my @ENDPOINTS = qw(
    bundesrat_startlist
    bundesrat_aktuelles
    bundesrat_termine
    bundesrat_plenum_kompakt
    bundesrat_plenum_aktuelle_sitzung
    bundesrat_plenum_chronologisch
    bundesrat_plenum_naechste_sitzungen
    bundesrat_mitglieder
    bundesrat_stimmverteilung
    bundesrat_praesidium
);

# MockIO: record the requests, answer with a small XML document
{
    package MockIO;
    use Moo;
    with 'WWW::Bund::Role::IO';

    has requests => (is => 'ro', default => sub { [] });

    sub call {
        my ($self, $req) = @_;
        push @{$self->requests}, $req;

        return WWW::Bund::HTTPResponse->new(
            status       => 200,
            content      => '<tagesordnungen><tagesordnung><name>Test-Sitzung</name></tagesordnung></tagesordnungen>',
            content_type => 'application/xml',
        );
    }
}

my $share = File::Spec->catdir($FindBin::Bin, '..', 'share');
my $reg = WWW::Bund::Registry->new(
    registry_file  => File::Spec->catfile($share, 'registry.yml'),
    endpoints_file => File::Spec->catfile($share, 'endpoints.yml'),
);

# Every Bundesrat endpoint asks for the XML view of the site by default
for my $name (@ENDPOINTS) {
    my $ep = $reg->endpoint($name);

    is($ep->{query_defaults}{view}, 'renderXml',
        "$name asks for the XML view of the site by default");

    ok(grep { $_ eq 'view' } @{ $ep->{query_params} // [] },
        "$name keeps view as a query parameter, so the caller can override it");
}

# The rule of the caller: a value the caller supplies beats the default
{
    my $cache_dir = File::Spec->catdir($FindBin::Bin, '..', '.test-cache-bundesrat');
    my $cache = WWW::Bund::Cache->new(cache_dir => $cache_dir);
    $cache->clear;

    my $mock = MockIO->new;
    my $caller = WWW::Bund::Caller->new(
        registry     => $reg,
        auth         => WWW::Bund::Auth->new,
        cache        => $cache,
        rate_limiter => WWW::Bund::RateLimit->new,
        io           => $mock,
    );

    # Without a value of the caller the default is sent
    {
        my $data = $caller->call('bundesrat', 'bundesrat_startlist');
        is($data->{tagesordnung}{name}, 'Test-Sitzung',
            'the answer of the Bundesrat endpoint is parsed as XML');

        my $url = $mock->requests->[-1]->url;
        like($url, qr/[?&]view=renderXml(?:&|$)/,
            'the default view=renderXml is sent');
    }

    # A value of the caller beats the default
    {
        $caller->call('bundesrat', 'bundesrat_startlist',
            params => { view => 'renderHtml' });

        my $url = $mock->requests->[-1]->url;
        like($url, qr/[?&]view=renderHtml(?:&|$)/,
            'the value of the caller is sent');
        unlike($url, qr/renderXml/,
            'the default is not sent when the caller supplies a value');
    }

    use File::Path qw(remove_tree);
    remove_tree($cache_dir) if -d $cache_dir;
}

done_testing;
