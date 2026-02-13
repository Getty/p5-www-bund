package WWW::Bund::RateLimit;

# ABSTRACT: Per-API rate limiting with sliding window

use Moo;
use Time::HiRes qw(time sleep);
use Carp qw(croak);
use namespace::clean;

=head1 SYNOPSIS

    use WWW::Bund::RateLimit;

    my $limiter = WWW::Bund::RateLimit->new(
        limits => {
            tagesschau => { max => 60, window => 3600 },
            smard      => { max => 60, window => 3600 },
        },
    );

    # Check rate limit (blocks if exceeded)
    $limiter->check('tagesschau');

=head1 DESCRIPTION

Enforces per-API rate limits using a sliding window algorithm. If the rate
limit is exceeded, C<check> will sleep until the oldest request falls outside
the window.

Currently configured limits:

=over

=item * tagesschau: 60 requests per hour

=item * smard: 60 requests per hour

=back

APIs without configured limits are not rate-limited.

=cut

has limits => (
    is      => 'ro',
    default => sub { {
        tagesschau => { max => 60, window => 3600 },
        smard      => { max => 60, window => 3600 },
    } },
);

=attr limits

HashRef of rate limit configurations per API. Each entry has:

=over

=item * C<max> - Maximum number of requests

=item * C<window> - Time window in seconds

=back

=cut

has _timestamps => (is => 'ro', default => sub { {} });

sub check {
    my ($self, $api) = @_;
    my $limit = $self->limits->{$api} or return 1;

    my $now = time();
    my $window = $limit->{window};
    my $max = $limit->{max};

    $self->_timestamps->{$api} ||= [];
    my $ts = $self->_timestamps->{$api};

    @$ts = grep { $_ > $now - $window } @$ts;

    if (scalar(@$ts) >= $max) {
        my $oldest = $ts->[0];
        my $wait = $oldest + $window - $now;
        if ($wait > 0) {
            sleep($wait);
            @$ts = grep { $_ > time() - $window } @$ts;
        }
    }

    push @$ts, time();
    return 1;
}

=method check

    $limiter->check($api_id);

Check rate limit for API. If limit is exceeded, sleeps until a request slot
becomes available.

Returns C<1> always (after potentially sleeping).

APIs without configured limits pass through immediately.

=cut

1;
