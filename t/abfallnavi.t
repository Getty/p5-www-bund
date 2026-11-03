#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(remove_tree);
use FindBin;
use JSON::MaybeXS qw(encode_json);

use WWW::Bund::Registry;
use WWW::Bund::Caller;
use WWW::Bund::Auth;
use WWW::Bund::Cache;
use WWW::Bund::RateLimit;
use WWW::Bund::HTTPResponse;

# Regression guard for karr k4: abfallnavi's regional {region} substitution.
#
# The abfallnavi endpoints carry base_url
#   https://{region}-abfallapp.regioit.de/abfall-app-{region}/rest
# and list `region` in query_params. Caller must substitute {region} into the
# base_url (host AND path segment) and DELETE it from the remaining params, so
# it is NOT also appended as a spurious ?region=... query string.
#
# This test is OFFLINE: a MockIO records the built HTTPRequest so we can assert
# on the exact URL without hitting the network.

# MockIO: record requests, return a canned JSON array (orte/strassen return arrays)
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
            content      => '[]',
            content_type => 'application/json',
        );
    }
}

my $share     = File::Spec->catdir($FindBin::Bin, '..', 'share');
my $cache_dir = File::Spec->catdir($FindBin::Bin, '..', '.test-cache-abfallnavi');
remove_tree($cache_dir) if -d $cache_dir;

my $registry = WWW::Bund::Registry->new(
    registry_file  => File::Spec->catfile($share, 'registry.yml'),
    endpoints_file => File::Spec->catfile($share, 'endpoints.yml'),
);

my $mock = MockIO->new;

my $caller = WWW::Bund::Caller->new(
    registry     => $registry,
    auth         => WWW::Bund::Auth->new,
    cache        => WWW::Bund::Cache->new(cache_dir => $cache_dir),
    rate_limiter => WWW::Bund::RateLimit->new,
    io           => $mock,
);

# --- orte: region only, no path param ------------------------------------
{
    $caller->call('abfallnavi', 'abfallnavi_orte',
        params => { region => 'nuernberg' },
    );

    my $req = $mock->requests->[-1];

    is(
        $req->url,
        'https://nuernberg-abfallapp.regioit.de/abfall-app-nuernberg/rest/orte',
        'orte: {region} substituted into host + path, no query string',
    );
    is($req->method, 'GET', 'orte: GET request');
    unlike($req->url, qr/\?/,            'orte: URL has no query string at all');
    unlike($req->url, qr/[?&]region=/,   'orte: region does not leak into query params');
    unlike($req->url, qr/\{region\}/,    'orte: no {region} placeholder left in URL');
}

# --- strassen: path param (ortId) + region -------------------------------
# Deeper endpoint. Guards that path substitution and region substitution
# coexist and neither leaks region into the query string.
{
    $caller->call('abfallnavi', 'abfallnavi_strassen',
        params => { ortId => 6756817, region => 'nuernberg' },
    );

    my $req = $mock->requests->[-1];

    is(
        $req->url,
        'https://nuernberg-abfallapp.regioit.de/abfall-app-nuernberg/rest/orte/6756817/strassen',
        'strassen: {region} in host/path AND {ortId} path param substituted, no query',
    );
    unlike($req->url, qr/\?/,          'strassen: URL has no query string');
    unlike($req->url, qr/[?&]region=/, 'strassen: region does not leak into query params');
    unlike($req->url, qr/\{/,          'strassen: no placeholders left in URL');
}

# --- missing region is a loud failure ------------------------------------
# Confirms the substitution is mandatory, not silently skipped.
{
    eval {
        $caller->call('abfallnavi', 'abfallnavi_orte');
        1;
    };
    like($@, qr/base_url parameter 'region'/,
        'orte: missing region croaks loudly');
}

remove_tree($cache_dir) if -d $cache_dir;

done_testing;
