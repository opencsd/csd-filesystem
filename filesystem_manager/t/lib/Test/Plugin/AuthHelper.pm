package Test::Plugin::AuthHelper;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:potatogim';

use Test::Class::Moose extends => 'Test::GMS';

use GMS::Plugin::AuthHelper;
use Mock::GMS;
use Test::MockModule;

has 'mock' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { []; },
    handles => {
        add_mock    => 'push',
        all_mocks   => 'elements',
        clear_mocks => 'clear',
    }
);

has 'plugin' => (
    is      => 'ro',
    isa     => 'GMS::Plugin::AuthHelper',
    lazy    => 1,
    default => sub
    {
        my $self = shift;

        GMS::Plugin::AuthHelper->new();
    },
);

has 'private_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub
    {
        my $key = <<"ENDL";
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQCqyUW2ohn5zK9PbvMZjSJlXfAw+g/fiZBz3obZ4ywW6ZinuMww
1G9YYJSoYFxDD/4NKceb904OPQ2v/kKrnA5rAwSoZhOjkWYNw4N8KGBMShZOlF0/
BQTo451UpfPzn0LDtOrapOxhqo5IugGwi/JX3dG0IGtVXs6alJK1LNmD9QIDAQAB
AoGAVTea9ndKGM/eRfdpi71VhVjrKbUMyJB+qKJHjV8CN+iVSFM4Z8EIUgPXCXET
eE75iB3pwNQUeZxTQRbQs4pp0oBPiqFTS/ADjxK2Tt7P5D0zgkCuJ7P6xO34/myU
/LxXrvldsw+xMvUYb5ilF3AAgWb5+KDZN7Qasf0W29oHwkECQQDi8ZAupSYSVe5G
RCnYem4ujv+48cP/OKRcwW7iOX0GrgkwhLbArHn6F6g0S+/pYz08b8h25yDkPR5H
xKhb5YhlAkEAwKcPyUj7Vk/MpVeL08Nd8kI1x+p0uDq4hhemP1RWgR+clKFJ/2ma
N1JuMTQkoLZAUCSmYZzgSdswsaklnigsUQJABceLGXUBPDROBiIUQrwTdEIWBxq5
GBXUMbyHW2GFapciCsdGdC+wR4s0sGhCqtnpJFHgdA68yrM3wzIh630z9QJADEsc
0MVddHaHIo3hmFPBLPJYqDcn15G3sKbVrvjcxESWI03fgPLmKl2SNoWTSMYYeIS+
MUBnd48LHmsiwWLi4QJAYcqoIOcoA8K3RZfCo4nlsaAxfKIJBiuPNA6tzqdIv0lS
h8PaXV4b7Tj4iKl45stOqUhbvGZaDRjl/h9vk6J6Ew==
-----END RSA PRIVATE KEY-----
ENDL
    }
);

has 'public_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub
    {
        my $key = <<"ENDL";
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAKrJRbaiGfnMr09u8xmNImVd8DD6D9+JkHPehtnjLBbpmKe4zDDUb1hg
lKhgXEMP/g0px5v3Tg49Da/+QqucDmsDBKhmE6ORZg3Dg3woYExKFk6UXT8FBOjj
nVSl8/OfQsO06tqk7GGqjki6AbCL8lfd0bQga1VezpqUkrUs2YP1AgMBAAE=
-----END RSA PUBLIC KEY-----
ENDL
    }
);

sub test_startup
{
    my $self = shift;

    $self->next::method(@_);
}

sub test_setup
{
    my $self = shift;

    $self->next::method(@_);

    my $method = $self->test_report->current_method;

    given ($method->name)
    {
        when ('test_encode_jwt_rsa')
        {
            if (!eval { load('Crypt::OpenSSL::RSA'); 1; })
            {
                $self->test_skip(
                    'This test will be skipped because could not find Crypt::OpenSSL::RSA'
                );
            }
        }
    }
}

# :TODO 12/01/2020 10:09:56 PM: by P.G.
# unit-test implementation for them
#sub test_authenticate : Tests
#{
#
#}
#
#sub test_generate_token : Tests
#{
#
#}

sub test_validate_token : Tests
{
    my $self = shift;

    ok(
        !$self->plugin->validate_token(token => ''),
        'JWT token validation with invalid token'
    );

    my $token
        = 'eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpZCI6InBvdGF0b2dpbSIsIm9yZyI6ImdsdWVzeXMifQ.j70vunyzbmhKziTIReRRjl9_SH_q9y9BMztGW1sLj3qq2OCTlrbevi8i1CWJ2QYfHBli4Vqt1GOPU-lYPgbh3kNTHTS_r7exLcMQmazjzoj8qpe7OG33ITTqLQBRFzO5xy2Wb9YtsTjL89crkYQhQbI_MKqvJSNvn5zhAGbm8SE';

    cmp_deeply(
        $self->plugin->validate_token(token => $token),
        {id => 'potatogim', org => 'gluesys'},
        'JWT token validation with valid token'
    );
}

sub test_encode_jwt : Tests
{
    my $self = shift;

    my $jwt = $self->plugin->encode_jwt(
        payload => {user => 'potatogim'},
        secret  => 'gluesys',
    );

    my $token
        = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoicG90YXRvZ2ltIn0.aH3nog1a6yS6L71P4XV4FwRu9_NIauyJ4qfrNGEURM4';

    cmp_ok($jwt, 'eq', $token, "JWT token encoded");

    $jwt = $self->plugin->encode_jwt(
        payload => {user => 'potatogim'},
        expires => 60,
        secret  => 'gluesys',
    );

    $token
        = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjYwLCJ1c2VyIjoicG90YXRvZ2ltIn0.ElN8usQUxd9ekatu9GKw7ORLPMpIZ0WiYlWudZ1BFFM';

    cmp_ok($jwt, 'eq', $token, "JWT token encoded");
}

sub test_encode_jwt_with_rsa : Tests
{
    my $self = shift;

    my %payload = (
        id  => 'potatogim',
        org => 'gluesys',
    );

    my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);

    my $jwt = $self->plugin->encode_jwt(
        payload   => \%payload,
        secret    => $self->private_key,
        algorithm => 'RS512',
    );

    my $token
        = 'eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpZCI6InBvdGF0b2dpbSIsIm9yZyI6ImdsdWVzeXMifQ.j70vunyzbmhKziTIReRRjl9_SH_q9y9BMztGW1sLj3qq2OCTlrbevi8i1CWJ2QYfHBli4Vqt1GOPU-lYPgbh3kNTHTS_r7exLcMQmazjzoj8qpe7OG33ITTqLQBRFzO5xy2Wb9YtsTjL89crkYQhQbI_MKqvJSNvn5zhAGbm8SE';

    cmp_ok($jwt, 'eq', $token, 'JWT token encoded with RSA is valid');
}

sub test_decode_jwt_with_rsa : Tests
{
    my $self = shift;

    my $token
        = 'eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpZCI6InBvdGF0b2dpbSIsIm9yZyI6ImdsdWVzeXMifQ.j70vunyzbmhKziTIReRRjl9_SH_q9y9BMztGW1sLj3qq2OCTlrbevi8i1CWJ2QYfHBli4Vqt1GOPU-lYPgbh3kNTHTS_r7exLcMQmazjzoj8qpe7OG33ITTqLQBRFzO5xy2Wb9YtsTjL89crkYQhQbI_MKqvJSNvn5zhAGbm8SE';

    $self->unmock_data();

    ok(
        !$self->plugin->decode_jwt(token => $token),
        'JWT token decoding without unregistered RSA key'
    );

    $self->mock_data(
        data => {
            '/Sessions' => {
                'localhost' => {
                    token       => $token,
                    public_key  => $self->public_key,
                    private_key => $self->private_key,
                }
            }
        }
    );

    my $jwt = $self->plugin->decode_jwt(token => $token);

    isa_ok($jwt, 'HASH');

    cmp_deeply(
        $jwt,
        {id => 'potatogim', org => 'gluesys'},
        'JWT token decoded with RSA is valid'
    );
}

sub mock_tx
{
    my $mock = Test::MockModule->new('GMS::Plugin::AuthHelper');

    $mock->mock(
        'tx' => sub
        {
            my $tx = Mojo::Transaction::HTTP->new();

            $tx->remote_address('localhost');

            return $tx;
        }
    );

    return $mock;
}

sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->add_mock(mock_tx());
}

1;

=encoding utf8

=head1 NAME

Test::Plugin::AuthHelper - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2020. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=head1 DATE

12/01/2020 07:44:14 PM

=cut

