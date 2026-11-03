#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode_utf8 decode);
use File::Spec;
use FindBin;
use HTTP::Response;

use WWW::Bund::Response::JSON;
use WWW::Bund::Response::XML;
use WWW::Bund::Response::Raw;
use WWW::Bund::LWPIO;
use WWW::Bund::HTTPRequest;
use WWW::Bund::CLI::Formatter;

my $templates_dir = File::Spec->catdir($FindBin::Bin, '..', 'share', 'templates');
my $strings_dir   = File::Spec->catdir($FindBin::Bin, '..', 'share', 'strings');

sub make_fmt {
    return WWW::Bund::CLI::Formatter->new(
        templates_dir => $templates_dir,
        strings_dir   => $strings_dir,
        lang          => 'de',
    );
}

# FakeUA: hands over a canned HTTP::Response
{
    package FakeUA;
    use Moo;

    has response => (is => 'ro', required => 1);

    sub request { $_[0]->response }
}

# --- JSON Response ---

{
    my $resp = WWW::Bund::Response::JSON->new(
        content      => '{"name":"test","value":42}',
        content_type => 'application/json',
    );
    is_deeply($resp->data, { name => 'test', value => 42 }, 'JSON: parses to hash');
}

{
    my $resp = WWW::Bund::Response::JSON->new(
        content      => '[1,2,3]',
        content_type => 'application/json',
    );
    is_deeply($resp->data, [1, 2, 3], 'JSON: parses array');
}

{
    my $resp = WWW::Bund::Response::JSON->new(content => '');
    is($resp->data, undef, 'JSON: empty content returns undef');
}

# --- XML Response ---

{
    my $xml = '<root><name>test</name><value>42</value></root>';
    my $resp = WWW::Bund::Response::XML->new(
        content      => $xml,
        content_type => 'application/xml',
    );
    my $data = $resp->data;
    is(ref $data, 'HASH', 'XML: returns hash');
    is($data->{name}, 'test', 'XML: simple element text');
    is($data->{value}, '42', 'XML: another element text');
}

{
    my $xml = '<root><item>a</item><item>b</item><item>c</item></root>';
    my $resp = WWW::Bund::Response::XML->new(content => $xml);
    my $data = $resp->data;
    is_deeply($data->{item}, ['a', 'b', 'c'], 'XML: repeated elements become array');
}

{
    my $xml = '<root><el id="x1">hello</el></root>';
    my $resp = WWW::Bund::Response::XML->new(content => $xml);
    my $data = $resp->data;
    is(ref $data->{el}, 'HASH', 'XML: element with attr+text is hash');
    is($data->{el}{id}, 'x1', 'XML: attribute preserved');
    is($data->{el}{_text}, 'hello', 'XML: text in _text key');
}

{
    my $xml = '<root><parent><child>val</child></parent></root>';
    my $resp = WWW::Bund::Response::XML->new(content => $xml);
    my $data = $resp->data;
    is($data->{parent}{child}, 'val', 'XML: nested elements');
}

{
    my $resp = WWW::Bund::Response::XML->new(content => '');
    is($resp->data, undef, 'XML: empty content returns undef');
}

# --- Raw Response ---

{
    my $resp = WWW::Bund::Response::Raw->new(
        content      => 'plain text here',
        content_type => 'text/plain',
    );
    is($resp->data, 'plain text here', 'Raw: returns content as-is');
}

{
    my $resp = WWW::Bund::Response::Raw->new(content => '');
    is($resp->data, '', 'Raw: empty content returns empty string');
}

# --- Raw Response: the body is decoded ---

# The transport hands the body over as bytes, the parser decodes them. Without
# the decoding the answer arrives as mojibake in the output.
{
    my $resp = WWW::Bund::Response::Raw->new(
        content      => encode_utf8('Grüße aus Köln'),
        content_type => 'text/plain; charset=utf-8',
    );

    is($resp->data, 'Grüße aus Köln', 'Raw: the body is decoded as UTF-8');
    ok(utf8::is_utf8($resp->data), 'Raw: the decoded body is a character string');
}

# The characters arrive in the output, not the bytes
{
    my $resp = WWW::Bund::Response::Raw->new(
        content      => encode_utf8('Grüße aus Köln'),
        content_type => 'text/plain; charset=utf-8',
    );
    my $fmt = make_fmt();

    my $json = $fmt->format_output($resp->data, undef, 'json');
    like($json, qr/\QGrüße aus Köln\E/, 'Raw: the JSON output shows the characters');

    # The YAML dump answers with a character string, the CLI writes it through
    # a UTF-8 output layer - the characters are what the user sees.
    my $yaml = $fmt->format_output($resp->data, undef, 'yaml');
    like($yaml, qr/\QGrüße aus Köln\E/, 'Raw: the YAML output shows the characters');
    unlike($yaml, qr/Ã/, 'Raw: the output carries no mojibake');
}

# A body that is not valid UTF-8 comes through unchanged and does not die
{
    my $broken = "Gr\x{fc}\x{df}e \xc3\x28";
    my $resp = eval {
        WWW::Bund::Response::Raw->new(
            content      => $broken,
            content_type => 'text/plain; charset=utf-8',
        );
    };
    ok(!$@, "Raw: a broken body does not die: $@");
    is($resp ? $resp->data : undef, $broken, 'Raw: a broken body comes through unchanged');
}

# A body that was decoded already is not decoded a second time
{
    my $decoded = decode('UTF-8', encode_utf8('Grüße aus Köln'));
    my $resp = WWW::Bund::Response::Raw->new(
        content      => $decoded,
        content_type => 'text/plain; charset=utf-8',
    );
    is($resp->data, 'Grüße aus Köln', 'Raw: a decoded body is not decoded twice');
}

# --- Role attributes ---

{
    my $resp = WWW::Bund::Response::JSON->new(
        content      => '{}',
        content_type => 'application/json; charset=utf-8',
    );
    is($resp->content, '{}', 'content attribute accessible');
    is($resp->content_type, 'application/json; charset=utf-8', 'content_type attribute accessible');
}

# --- Transport: the body is handed over as bytes ---

# A JSON body that is served as text/plain must not die in decode_json
{
    my $body = encode_utf8('{"name":"Müller €"}');
    my $http = HTTP::Response->new(
        200, 'OK', ['Content-Type' => 'text/plain; charset=utf-8'], $body,
    );

    my $io = WWW::Bund::LWPIO->new(ua => FakeUA->new(response => $http));
    my $resp = $io->call(
        WWW::Bund::HTTPRequest->new(method => 'GET', url => 'https://example.org/data')
    );

    ok(!utf8::is_utf8($resp->content), 'the transport hands over bytes');
    is($resp->content, $body, 'the bytes are unchanged');
    is($resp->content_type, 'text/plain; charset=utf-8', 'the content type is passed on');

    my $data = eval {
        WWW::Bund::Response::JSON->new(
            content      => $resp->content,
            content_type => $resp->content_type,
        )->data;
    };
    ok(!$@, "JSON as text/plain decodes without dying: $@");
    is($data ? $data->{name} : undef, 'Müller €', 'the characters survive the round trip');
}

# The same for XML: the parser gets the bytes and decodes them
{
    my $body = encode_utf8('<root><name>Müller €</name></root>');
    my $http = HTTP::Response->new(
        200, 'OK', ['Content-Type' => 'text/xml; charset=utf-8'], $body,
    );

    my $io = WWW::Bund::LWPIO->new(ua => FakeUA->new(response => $http));
    my $resp = $io->call(
        WWW::Bund::HTTPRequest->new(method => 'GET', url => 'https://example.org/data')
    );

    ok(!utf8::is_utf8($resp->content), 'the transport hands over bytes');

    my $data = eval {
        WWW::Bund::Response::XML->new(
            content      => $resp->content,
            content_type => $resp->content_type,
        )->data;
    };
    ok(!$@, "XML as text/xml parses without dying: $@");
    is($data ? $data->{name} : undef, 'Müller €', 'the characters survive the round trip');
}

done_testing;
