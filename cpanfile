requires 'File::ShareDir';
requires 'File::ShareDir::ProjectDistDir';
requires 'HTTP::Request';
requires 'JSON::MaybeXS';
requires 'Log::Any';
requires 'LWP::Protocol::https';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'MooX::Cmd';
requires 'MooX::Options';
requires 'namespace::clean';
requires 'URI::Escape';
requires 'XML::Twig';
requires 'YAML::PP';

on test => sub {
    requires 'Path::Tiny';
    requires 'Test::Exception';
    requires 'Test::More';
};
