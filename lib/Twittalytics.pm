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
  template 'layouts/main';
};

get '/*' => sub {
  template 'layouts/main';
};

# API
prefix '/api';

get "/users/:username/recent_statuses" => sub {
  content_type 'application/json';

  my $twitter_client = Services::TwitterClient->new;
  return $twitter_client->get_statuses_for_user(params->{username});
};

get "/users/common_friends" => sub {
  content_type 'application/json';

  unless ( params->{username1} && params->{username2} ) {
    return to_json({error => "Please pass username1 and username2 as params"});
  }

  my $twitter_client = Services::TwitterClient->new;
  return $twitter_client->get_common_friends(params->{username1}, params->{username2});
};

1;
