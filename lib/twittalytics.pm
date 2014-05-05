package Twittalytics;

use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Sys::Hostname;

# Services
use Services::TwitterClient;

our $VERSION = '0.1';

prefix '/api';

get "/users/:username/recent_statuses" => sub {
  my $twitter_client = Services::TwitterClient->new;
  content_type 'application/json';
  return $twitter_client->get_statuses_for_user(params->{username});
};

1;
