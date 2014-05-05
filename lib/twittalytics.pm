package Twittalytics;

use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Sys::Hostname;

# Services
use Services::TwitterClient;

our $VERSION = '0.1';

get '/' => sub {
  my $twitter_client = Services::TwitterClient->new;
  return $twitter_client->fetch_bearer_token;
};

1;
