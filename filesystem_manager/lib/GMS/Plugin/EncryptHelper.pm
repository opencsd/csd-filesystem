package GMS::Plugin::EncryptHelper;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Crypt::Mode::CTR;
use Crypt::AES::CTR;
use Crypt::OpenSSL::RSA;
use Mojo::Util qw/b64_encode b64_decode/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my $self = shift;
    my $app  = shift;
    my $args = shift;

    $app->helper(aes_encrypt => \&aes_encrypt);
    $app->helper(aes_decrypt => \&aes_decrypt);

    $app->helper(rsa_encrypt => \&rsa_encrypt);
    $app->helper(rsa_decrypt => \&rsa_decrypt);

    return;
}

sub aes_encrypt
{
    my $c    = shift;
    my %args = @_;

    my $cipher = $args{cipher};
    my $key    = $args{key};

    return Crypt::AES::CTR::encrypt($cipher, $key, 256);
}

sub aes_decrypt
{
    my $c    = shift;
    my %args = @_;

    my $cipher = $args{cipher};
    my $key    = $args{key};

    return Crypt::AES::CTR::decrypt($cipher, $key, 256);
}

sub rsa_encrypt
{
    my $c    = shift;
    my %args = @_;

    my $pubkey = $c->get_pubkey();
    my $rsa    = Crypt::OpenSSL::RSA->new_public_key($pubkey);

    $rsa->use_pkcs1_padding();

    return b64_encode($rsa->encrypt($args{data}));
}

sub rsa_decrypt
{
    my $c    = shift;
    my %args = @_;

    my $privkey = $c->get_privkey();
    my $rsa     = Crypt::OpenSSL::RSA->new_private_key($privkey);

    $rsa->use_pkcs1_padding();

    return $rsa->decrypt(b64_decode($args{data}));
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::EncryptHelper - GMS encryption/decryption helper

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
