#
# Crypt::HCE_MD5
# implements one way hash chaining encryption using MD5
#
# $Id$
#

package Crypt::HCE_MD5;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use MD5;
use MIME::Base64;
use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.02';

sub new {
    my $class = shift;
    my $self = {};
 
    bless $self, $class;
 
    if (scalar(@_) != 2) {
        croak "Error: must be invoked HCE_MD5->new(key, random_thing)";
    }
 
    $self->{SKEY} = shift(@_);
    $self->{RKEY} = shift(@_);
 
    return $self;
}
 
sub _new_key {
    my $self = shift;
    my ($rnd) = @_;
 
    my $context = new MD5;
    $context->add($self->{SKEY}, $rnd);
    my $digest = $context->digest();
    my @e_block = unpack('C*', $digest);
    return @e_block;
}
 
sub hce_block_encrypt {
    my $self = shift;
    my ($data) = @_;
    my ($i, $key, $data_size, $ans, $mod, @e_block, @data, @key, @ans);
 
    @key = unpack ('C*', $self->{SKEY});
    @data = unpack ('C*', $data);
    
    undef @ans;
    @e_block = $self->_new_key($self->{RKEY});
    $data_size = scalar(@data);
    for($i=0; $i < $data_size; $i++) {
        $mod = $i % 16;
        if (($mod == 0) && ($i > 15)) {
            @e_block = $self->_new_key((@ans)[($i-16)..($i-1)]);
        }
        $ans[$i] = $e_block[$mod] ^ $data[$i];
    }
    $ans = pack 'C*', @ans;
    return $ans;
}

sub hce_block_decrypt {
    my $self = shift;
    my ($data) = @_;
    my ($i, $key, $data_size, $ans, $mod, @e_block, @data, @key, @ans);
 
    @key = unpack ('C*', $self->{SKEY});
    @data = unpack ('C*', $data);
    
    undef @ans;
    @e_block = $self->_new_key($self->{RKEY});
    $data_size = scalar(@data);
    for($i=0; $i < $data_size; $i++) {
        $mod = $i % 16;
        if (($mod == 0) && ($i > 15)) {
            @e_block = $self->_new_key((@data)[($i-16)..($i-1)]);
        }
        $ans[$i] = $e_block[$mod] ^ $data[$i];
    }
    $ans = pack 'C*', @ans;
    return $ans;
}

sub hce_block_encode_mime {
    my $self = shift;
    my ($data) = @_;
    
    my $new_data = $self->hce_block_encrypt($data);
    my $encode = encode_base64($new_data);
    return $encode;
}
 
sub hce_block_decode_mime {
    my $self = shift;
    my ($data) = @_;
    
    my $decode = decode_base64($data);
    my $new_data = $self->hce_block_decrypt($decode);
    return $new_data;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Crypt::HCE_MD5 - Perl extension implementing one way hash chaining encryption using MD5

=head1 SYNOPSIS

  use Crypt::HCE_MD5;
  
  $hce_md5 = Crypt::HCE_MD5->new("SharedSecret", "Random01,39j309ad");
  
  $crypted = $hce_md5->hce_block_encrypt("Encrypt this information");
  $info = $hce_md5->hce_block_decrypt($crypted);

  $mime_crypted = $hce_md5->hce_block_encode_mime("Encrypt and Base64 this information");
  $info = $hce_md5->hce_block_decode_mime($mime_crypted);
  
 
=head1 DESCRIPTION

This module implements a chaining block cipher using a one way hash.  This method of encryption is the same that is used by radius (RFC2138) and is also described in Applied Cryptography.

Two interfaces are provided in the module.  The first is straight block encryption/decryption the second does base64 mime encoding/decoding of the encrypted/decrypted blocks.

The idea is the the two sides have a shared secret that supplies one of the keys and a randomly generated block of bytes provides the second key.  The random key is passed in cleartext between the two sides.

An example client and server are packaged as modules with this module.  They are used in the tests.

=head1 AUTHOR

Eric Estabrooks, estabroo@ispn.com

=head1 SEE ALSO

perl(1).

=cut