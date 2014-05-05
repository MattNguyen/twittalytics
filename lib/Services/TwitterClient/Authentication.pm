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
use Data::Dumper;

# Source .env file
# TODO - Refactor this out into another object. -MN 20140505
BEGIN {
  sub source_env {
    open(my $fh, "<", ".env") || die "Could not open .env: $!";

    while (<$fh>) {
      chomp;
      my ($k, $v) = split /=/, $_, 2;
      $ENV{$k} = $v;
    }
  }

  source_env;

  die("Please set TWITTER_API_KEY in your .env file") unless $ENV{"TWITTER_API_KEY"};
  die("Please set TWITTER_API_SECRET in your .env file") unless $ENV{"TWITTER_API_SECRET"};
}

has 'consumer_key'    => (isa => 'Str', is => 'ro', default => $ENV{"TWITTER_API_KEY"});
has 'consumer_secret' => (isa => 'Str', is => 'ro', default => $ENV{"TWITTER_API_SECRET"});
has 'base_uri'        => (isa => 'Str', is => 'ro', default => 'https://api.twitter.com/');
has 'bearer_token'    => (isa => 'Str', is => 'rw');

sub fetch_bearer_token {
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
  return encode_base64(uri_escape($self->consumer_key) . ':' . uri_escape($self->consumer_secret), '');
}

sub _authentication_url {
  my $self = shift;
  return $self->base_uri . 'oauth2/token';
}

sub _get_user_url {
  my $self = shift;
  return $self->base_uri . 'users/show';
}

 __PACKAGE__->meta->make_immutable;

1;
