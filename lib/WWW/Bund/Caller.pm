package WWW::Bund::Caller;
our $VERSION = '0.003';
# ABSTRACT: Generic API call engine

use Moo;
use WWW::Bund::HTTPRequest;
use WWW::Bund::Response::JSON;
use WWW::Bund::Response::XML;
use WWW::Bund::Response::Raw;
use URI::Escape qw(uri_escape);
use Log::Any qw($log);
use Carp qw(croak);
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::Caller;

    my $caller = WWW::Bund::Caller->new(
        registry     => $registry,
        auth         => $auth,
        cache        => $cache,
        rate_limiter => $rate_limiter,
        io           => $io,
    );

    my $data = $caller->call('autobahn', 'autobahn_roads');
    my $data = $caller->call('autobahn', 'autobahn_webcams',
        params => { roadId => 'A7' }
    );

=head1 DESCRIPTION

The call engine coordinates endpoint lookup, URL building, path parameter
substitution, authentication, rate limiting, caching, HTTP execution, and
response parsing.

Flow:

=over

=item 1. Look up endpoint metadata from registry

=item 2. Build URL with path and query parameters

=item 3. Check cache (GET only)

=item 4. Check rate limit (only when the response is not cached)

=item 5. Add authentication headers

=item 6. Execute HTTP request via IO adapter

=item 7. Parse response (JSON, XML, or raw)

=item 8. Cache response (GET only)

=item 9. Return parsed data

=back

=cut

has registry => (is => 'ro', required => 1);

=attr registry

L<WWW::Bund::Registry> instance for endpoint lookup. Required.

=cut

has auth => (is => 'ro', required => 1);

=attr auth

L<WWW::Bund::Auth> instance for authentication headers. Required.

=cut

has cache => (is => 'ro', required => 1);

=attr cache

L<WWW::Bund::Cache> instance for response caching. Required.

=cut

has rate_limiter => (is => 'ro', required => 1);

=attr rate_limiter

L<WWW::Bund::RateLimit> instance for rate limiting. Required.

=cut

has io => (is => 'ro', required => 1);

=attr io

HTTP client implementing L<WWW::Bund::Role::IO>. Required.

=cut

sub call {
    my ($self, $api, $endpoint_name, %opts) = @_;

    my $endpoint = $self->registry->endpoint($endpoint_name);
    croak "Endpoint '$endpoint_name' belongs to API '$endpoint->{api}', not '$api'"
        if $endpoint->{api} ne $api;

    my $method   = uc($endpoint->{method});
    my $base_url = $opts{base_url} // $endpoint->{base_url};
    my $path     = $endpoint->{path};
    my $params   = $opts{params} // {};

    croak "No base_url for endpoint '$endpoint_name'" unless $base_url;

    # Substitute base_url parameters (e.g., {region} for abfallnavi)
    my %remaining_params = %$params;
    while ($base_url =~ /\{([^}]+)\}/g) {
        my $param = $1;
        croak "Missing base_url parameter '$param' for endpoint '$endpoint_name'"
            unless exists $remaining_params{$param};
        my $value = uri_escape(delete $remaining_params{$param});
        $base_url =~ s/\{\Q$param\E\}/$value/g;  # Replace all occurrences
    }

    # Substitute path parameters
    while ($path =~ /\{([^}]+)\}/g) {
        my $param = $1;
        croak "Missing path parameter '$param' for endpoint '$endpoint_name'"
            unless exists $remaining_params{$param};
        my $value = uri_escape(delete $remaining_params{$param});
        $path =~ s/\{\Q$param\E\}/$value/;
    }

    # Build URL
    $base_url =~ s{/$}{};
    $path =~ s{^/}{};
    my $url = "$base_url/$path";

    # Apply endpoint query defaults (caller-supplied values win)
    if (my $defaults = $endpoint->{query_defaults}) {
        for my $k (keys %$defaults) {
            $remaining_params{$k} = $defaults->{$k}
                unless exists $remaining_params{$k};
        }
    }

    # Inject query-param auth token from the environment when configured and set
    # (e.g. ArcGIS ?token=). Caller-supplied value wins; absent env var = omitted.
    my $auth_param;
    if (my $env = $endpoint->{auth_env}) {
        my $param = $endpoint->{auth_query_param} // 'token';
        if (!exists $remaining_params{$param} && defined(my $token = $ENV{$env})) {
            $remaining_params{$param} = $token;
            $auth_param = $param;
        }
    }

    # Prepare body content for POST/PUT
    my $body_content;
    my @param_pairs;
    my $secret_pair;
    if (%remaining_params) {
        for my $k (sort keys %remaining_params) {
            my $v = $remaining_params{$k};
            next unless defined $v;
            my $pair = uri_escape($k) . '=' . uri_escape($v);
            push @param_pairs, $pair;
            $secret_pair = $pair if defined $auth_param && $k eq $auth_param;
        }
    }

    # Append query params for GET, use body for POST/PUT
    if ($method eq 'GET' && @param_pairs) {
        $url .= '?' . join('&', @param_pairs);
    } elsif (($method eq 'POST' || $method eq 'PUT') && @param_pairs) {
        $body_content = join('&', @param_pairs);
    }

    # The token from the environment is a secret and must not show up in a log
    # line or in an error message. Log lines and exceptions use a masked copy
    # of the URL; the request itself and the cache key keep the real one.
    my $display_url = $url;
    if (defined $secret_pair) {
        my $masked_pair = uri_escape($auth_param) . '=***';
        (my $masked_url = $url) =~ s/\Q$secret_pair\E/$masked_pair/;
        $display_url = $masked_url;
    }

    # Cache check (GET only)
    my $cache_key;
    my $cache_ttl = $endpoint->{cache_ttl};
    if ($method eq 'GET') {
        $cache_key = "$method $url";
        if (my $cached = $self->cache->get($cache_key, $cache_ttl)) {
            $log->debug("Cache hit: $method $display_url");
            return $self->_build_response($cached)->data;
        }
    }

    $log->debug("$method $display_url" . ($body_content ? " (body: " . length($body_content) . " bytes)" : ""));

    # Build headers
    my %headers = ('Accept' => 'application/json, application/xml, */*');
    if ($body_content) {
        $headers{'Content-Type'} = 'application/x-www-form-urlencoded';
    }
    my $auth_headers = $self->auth->headers_for($api);
    @headers{keys %$auth_headers} = values %$auth_headers;

    # Build and execute request
    my $req = WWW::Bund::HTTPRequest->new(
        method  => $method,
        url     => $url,
        headers => \%headers,
        ($body_content ? (content => $body_content) : ()),
    );

    # Rate limiting: only a request against the API consumes the quota, a
    # cache hit is no request and must not be counted.
    $self->rate_limiter->check($api);

    my $response = $self->io->call($req);

    unless ($response->status >= 200 && $response->status < 300) {
        $log->errorf("API error: %s %s -> %s", $method, $display_url, $response->status);
        croak "Bund API error: HTTP " . $response->status . " for $method $display_url";
    }

    $log->infof("%s %s -> %s", $method, $display_url, $response->status);

    # Cache response
    if ($cache_key && $response->content) {
        $self->cache->set($cache_key, $response->content);
    }

    return $self->_build_response($response->content, $response->content_type)->data;
}

=method call

    my $data = $caller->call($api_id, $endpoint_name, %options);

Execute an API call. Returns parsed data (HashRef or ArrayRef).

Options:

=over

=item * C<params> - HashRef of path and query parameters

=item * C<base_url> - Override endpoint's base URL

=back

An endpoint may declare a C<query_defaults> map of fixed query values (applied
only for keys the caller did not supply) and, for query-parameter token auth
such as ArcGIS, an C<auth_env>/C<auth_query_param> pair: when the named
environment variable is set, its value is injected as that query parameter.
That token is a secret: log lines and error messages show it masked as
C<token=***>, the request itself sends the real value.

Path parameters (C<{roadId}> in path) are substituted first. Remaining
parameters are:

=over

=item * Added as query params for GET requests

=item * Sent as form-encoded body for POST/PUT requests (Content-Type: application/x-www-form-urlencoded)

=back

The rate limit is only consulted when the response is not served from the
cache: a cache hit is no request against the API and does not consume the
quota.

Throws exception on HTTP errors (non-2xx status codes) or missing endpoints.

=cut

sub _build_response {
    my ($self, $content, $content_type) = @_;
    $content_type //= '';

    if ($content_type =~ m{application/json} || $content =~ /^\s*[\{\[]/) {
        return WWW::Bund::Response::JSON->new(
            content => $content, content_type => $content_type,
        );
    }
    if ($content_type =~ m{(?:application|text)/xml} || $content =~ /^\s*</) {
        return WWW::Bund::Response::XML->new(
            content => $content, content_type => $content_type,
        );
    }
    return WWW::Bund::Response::Raw->new(
        content => $content, content_type => $content_type,
    );
}

1;
