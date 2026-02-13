package WWW::Bund::Registry;

# ABSTRACT: API registry and endpoint catalog

use Moo;
use YAML::PP qw(LoadFile);
use File::ShareDir::ProjectDistDir;
use Carp qw(croak);
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::Registry;

    my $registry = WWW::Bund::Registry->new(
        registry_file  => 'share/registry.yml',
        endpoints_file => 'share/endpoints.yml',
    );

    # List all APIs
    my $all = $registry->list;
    my $traffic = $registry->list(tag => 'traffic');
    my $public = $registry->list(auth => 'none');

    # Search APIs
    my $results = $registry->search('autobahn');

    # Get API info
    my $info = $registry->info('autobahn');

    # Get endpoint
    my $ep = $registry->endpoint('autobahn_roads');

    # List endpoints for API
    my $endpoints = $registry->endpoints_for_api('autobahn');

=head1 DESCRIPTION

Loads and indexes API and endpoint metadata from YAML files. The registry
contains 31 APIs, and the endpoint catalog defines 78 endpoints across
implemented APIs.

=cut

has registry_file => (
    is      => 'lazy',
    builder => sub {
        dist_file('WWW-Bund', 'registry.yml');
    },
);

=attr registry_file

Path to registry YAML file. Defaults to C<share/registry.yml> from distribution.

=cut

has endpoints_file => (
    is      => 'lazy',
    builder => sub {
        dist_file('WWW-Bund', 'endpoints.yml');
    },
);

=attr endpoints_file

Path to endpoints YAML file. Defaults to C<share/endpoints.yml> from distribution.

=cut

has _registry => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        my $data = LoadFile($self->registry_file);
        my %by_id;
        for my $entry (@$data) {
            $by_id{$entry->{id}} = $entry;
        }
        return \%by_id;
    },
);

has _endpoints => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        my $data = LoadFile($self->endpoints_file);
        my %by_name;
        for my $entry (@$data) {
            $by_name{$entry->{name}} = $entry;
        }
        return \%by_name;
    },
);

sub list {
    my ($self, %filters) = @_;
    my @apis = values %{$self->_registry};

    if (my $tag = $filters{tag}) {
        @apis = grep {
            my $tags = $_->{tags} || [];
            grep { $_ eq $tag } @$tags;
        } @apis;
    }

    if (my $auth = $filters{auth}) {
        @apis = grep { ($_->{auth} // 'none') eq $auth } @apis;
    }

    return [ sort { $a->{id} cmp $b->{id} } @apis ];
}

=method list

    my $apis = $registry->list;
    my $apis = $registry->list(tag => 'traffic');
    my $apis = $registry->list(auth => 'none');

List all APIs, optionally filtered by tag or auth type. Returns ArrayRef of
API metadata HashRefs (id, title, provider, auth, tags, etc.).

=cut

sub search {
    my ($self, $query) = @_;
    my $q = lc($query);
    my @apis = values %{$self->_registry};

    return [ grep {
        lc($_->{id}) =~ /\Q$q\E/
        || lc($_->{title} // '') =~ /\Q$q\E/
        || lc($_->{provider} // '') =~ /\Q$q\E/
        || grep { lc($_) =~ /\Q$q\E/ } @{$_->{tags} || []}
    } @apis ];
}

=method search

    my $results = $registry->search('autobahn');

Search for APIs by substring match (case-insensitive) in ID, title, provider,
or tags. Returns ArrayRef of matching APIs.

=cut

sub info {
    my ($self, $id) = @_;
    return $self->_registry->{$id}
        || croak "Unknown API: $id";
}

=method info

    my $info = $registry->info('autobahn');

Get full metadata for an API by ID. Returns HashRef with id, title, provider,
auth, tags, docs_url, spec_url, rate_limit, etc.

Throws exception if API not found.

=cut

sub endpoint {
    my ($self, $name) = @_;
    return $self->_endpoints->{$name}
        || croak "Unknown endpoint: $name";
}

=method endpoint

    my $ep = $registry->endpoint('autobahn_roads');

Get endpoint metadata by name. Returns HashRef with name, api, base_url, path,
method, cache_ttl, query_params, etc.

Throws exception if endpoint not found.

=cut

sub endpoints_for_api {
    my ($self, $api_id) = @_;
    return [
        grep { $_->{api} eq $api_id }
        values %{$self->_endpoints}
    ];
}

=method endpoints_for_api

    my $endpoints = $registry->endpoints_for_api('autobahn');

List all endpoints belonging to an API. Returns ArrayRef of endpoint HashRefs.

=cut

1;
