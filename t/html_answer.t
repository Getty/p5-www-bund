use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Spec;
use File::Path qw(remove_tree);
use FindBin;

use WWW::Bund::Registry;
use WWW::Bund::Caller;
use WWW::Bund::Auth;
use WWW::Bund::Cache;
use WWW::Bund::RateLimit;
use WWW::Bund::HTTPResponse;
use WWW::Bund::Response::XML;

# Regression guard for karr k24: an API that answers with its web page instead
# of the requested XML.
#
# The caller picks the XML parser as soon as the body starts with '<'. A HTML
# document then died with 'syntax error at line 1, column 0, byte 0', a parser
# message that says nothing about what actually happened. The XML parser
# recognises a web page now and reports it in clear words.
#
# This test is OFFLINE: the caller is fed with a MockIO that returns a HTML
# body, no request goes out to a real API.

# MockIO: record requests, return a canned answer
{
    package MockIO;
    use Moo;
    with 'WWW::Bund::Role::IO';

    has requests => (is => 'ro', default => sub { [] });

    has content      => (is => 'ro', default => '');
    has content_type => (is => 'ro', default => 'text/html');

    sub call {
        my ($self, $req) = @_;
        push @{$self->requests}, $req;
        return WWW::Bund::HTTPResponse->new(
            status       => 200,
            content      => $self->content,
            content_type => $self->content_type,
        );
    }
}

# The HTML starters the parser has to recognise
my %html_answer = (
    'doctype' => '<!doctype html><html lang="de"><head><title>Bundesrat</title></head>'
        . '<body><p>Der Bundesrat</p></body></html>',
    'html'    => '<html lang="de"><head><title>Bundesrat</title></head>'
        . '<body><p>Der Bundesrat</p></body></html>',
    'head'    => '<head><title>Bundesrat</title></head>',
    'body'    => '<body><p>Der Bundesrat</p></body>',
);

# --- the parser reports a web page ----------------------------------------
for my $kind (sort keys %html_answer) {
    my $content = $html_answer{$kind};

    my $err = do {
        local $@;
        eval { WWW::Bund::Response::XML->new(content => $content)->data; 1 } or $@;
    };

    like($err, qr/web page/i, "$kind: a web page is reported as such");
    like($err, qr/HTML/,       "$kind: the message says HTML");
    unlike($err, qr/syntax error/i,
        "$kind: no parser error instead of a clear message");
    unlike($err, qr/Bundesrat/,
        "$kind: the message does not quote the body");
}

# The detection is case insensitive and ignores leading whitespace
{
    my $err = do {
        local $@;
        eval {
            WWW::Bund::Response::XML->new(
                content => "\n  <!DOCTYPE HTML><html></html>",
            )->data;
            1;
        } or $@;
    };

    like($err, qr/web page/i,
        'upper case doctype with leading whitespace is a web page too');
}

# --- an XML declaration is no web page ------------------------------------
# A document with an 'html' root element that is delivered as XML stays XML.
{
    my $data = WWW::Bund::Response::XML->new(
        content => '<?xml version="1.0" encoding="UTF-8"?><html><body>Hallo</body></html>',
    )->data;

    is(ref $data, 'HASH', 'a document with an XML declaration is parsed');
    is($data->{body}, 'Hallo', 'the XML content is parsed, not rejected');
}

# --- a real XML document is still parsed ----------------------------------
{
    my $data = WWW::Bund::Response::XML->new(
        content => '<tagesordnungen><tagesordnung><date>01.01.2025</date>'
            . '</tagesordnung></tagesordnungen>',
    )->data;

    is(ref $data, 'HASH', 'an XML document is parsed to a hash');
    is($data->{tagesordnung}{date}, '01.01.2025', 'the XML content is intact');
}

# --- the way through the caller --------------------------------------------
{
    my $share     = File::Spec->catdir($FindBin::Bin, '..', 'share');
    my $cache_dir = File::Spec->catdir($FindBin::Bin, '..', '.test-cache-html');
    remove_tree($cache_dir) if -d $cache_dir;

    my $registry = WWW::Bund::Registry->new(
        registry_file  => File::Spec->catfile($share, 'registry.yml'),
        endpoints_file => File::Spec->catfile($share, 'endpoints.yml'),
    );

    my $mock = MockIO->new(
        content      => $html_answer{'doctype'},
        content_type => 'text/html',
    );

    my $caller = WWW::Bund::Caller->new(
        registry     => $registry,
        auth         => WWW::Bund::Auth->new,
        cache        => WWW::Bund::Cache->new(cache_dir => $cache_dir),
        rate_limiter => WWW::Bund::RateLimit->new,
        io           => $mock,
    );

    my $err = do {
        local $@;
        eval { $caller->call('bundesrat', 'bundesrat_aktuelles'); 1 } or $@;
    };

    like($err, qr/web page/i,
        'the caller passes the clear message on');
    unlike($err, qr/syntax error/i,
        'the caller does not die with a parser error');

    remove_tree($cache_dir) if -d $cache_dir;
}

done_testing;
