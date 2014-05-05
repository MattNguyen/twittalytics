package Services::TwitterClient::Authentication;

use Dancer ':syntax';
use Moose;
use namespace::autoclean;
use Dancer::Plugin::Redis;
use HTTP::Request::Common;
use LWP::UserAgent;
use MIME::Base64;
use Encode qw/encode_utf8/;
use URI::Escape;
use Models::Environment;

has 'environment'     => (isa => "Models::Environment", is => 'ro', default => sub { Models::Environment->new });
has 'base_uri'        => (isa => 'Str', is => 'ro', default => 'https://api.twitter.com/');
has 'bearer_token'    => (isa => 'Str', is => 'rw');

sub get_bearer_token {
  my $self = shift;

  if ($self->_bearer_token_exists) {
    return $self->_bearer_token;
  } else {
    my $parsed_response = from_json($self->_authentication_response->content);

    # Save bearer_token in redis
    info "Saving 'bearer_token' to redis";
    redis->set(bearer_token => $parsed_response->{access_token});

    return $parsed_response->{access_token};
  }
}

# Private Methods

sub _bearer_token_exists {
  my $self = shift;
  return $self->_bearer_token;
}

sub _bearer_token {
  my $self = shift;
  return $self->bearer_token if $self->bearer_token;

  my $bearer_token_from_redis = redis->get('bearer_token') || "";
  info("'bearer_token' found in redis") if $bearer_token_from_redis;

  return $self->bearer_token($bearer_token_from_redis);
}

sub _authentication_response {
  my $self = shift;

  my $response = $self->_authentication_request->post($self->_authentication_url, [
    'grant_type' => 'client_credentials',
  ]);

  return $response;
}

sub _authentication_request {
  my $self = shift;
  my $user_agent = LWP::UserAgent->new;

  $user_agent->default_header('Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8');
  $user_agent->default_header('Authorization' => "Basic " . $self->_encoded_bearer_token_credentials);

  return $user_agent
}

sub _encoded_bearer_token_credentials {
  my $self = shift;
  my $concat_key_secret = uri_escape($self->environment->twitter_api_key) . ':' . uri_escape($self->environment->twitter_api_secret);
  return encode_base64($concat_key_secret, '');
}

sub _authentication_url {
  my $self = shift;
  return $self->base_uri . 'oauth2/token';
}

 __PACKAGE__->meta->make_immutable;

1;
