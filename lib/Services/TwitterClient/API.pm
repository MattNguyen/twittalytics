package Services::TwitterClient::API;

use Dancer ':syntax';
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Services::TwitterClient::Authentication;
use Dancer::Plugin::Redis;
use Models::Tweet;
use HTTP::Date;

has 'base_uri' => (isa => 'Str', is => 'ro', default => 'https://api.twitter.com/1.1/');

sub get_statuses_for_user {
  my ($self, $username) = @_;
  my $response;
  my $parsed_response;
  my $serialized_response;

  if (redis->hexists($username, "request_date")) {
    info "Username '$username' found in cache.";

    my $ttl = 60*60*24;
    my $cached_tweets = redis->hget($username, 'tweets');
    my $request_date  = str2time(redis->hget($username, 'request_date'));
    my $current_date  = str2time(scalar localtime);

    # Compare current date with request_date.
    # if request date is at least $ttl seconds older than current date,
    #   then make request
    # otherwise
    #   use redis data
    if ($current_date > ($request_date + $ttl)) {
      info "Data over TTL time. Renewing stale data...";

      $response        = $self->_response($self->_get_user_timeline_url($username));
      $parsed_response = from_json($response->content);

      my @new_tweets                 = map { Models::Tweet->new($_) } @$parsed_response;
      my $deserialized_cache         = from_json($cached_tweets);
      my @deserialized_cached_tweets = @{$deserialized_cache->{tweets}};
      my @cached_tweet_objects       = map { Models::Tweet->new($_) } @deserialized_cached_tweets;
      my $first_cached_tweet         = $cached_tweet_objects[0];
      my @tweet_results;

      # Compare ID of first tweet in cached_tweets array
      # Search new tweets array for tweet with first cached_tweet id
      # Grab newest tweets in array up until first cached_tweet
      # Append cached_tweets to new tweets
      if (grep($_->id == $first_cached_tweet->id, @new_tweets)) {
        my @newest_tweets;
        foreach my $new_tweet (@new_tweets) {
          last if $new_tweet->id == $first_cached_tweet->id;
          push @newest_tweets, $new_tweet;
        }
        if (@newest_tweets) {
          @tweet_results = push @newest_tweets, @cached_tweet_objects;
        } else {
          @tweet_results = @cached_tweet_objects;
        }
      } else {
        @tweet_results = push @new_tweets, @cached_tweet_objects;
      }

      $serialized_response = to_json({ tweets => \@tweet_results });

      redis->hmset($username,
        "request_date" => $response->header('Date'),
        "tweets" => $serialized_response,
      );
    } else {
      info "Data under TTL threshold. Using cached tweets.";
      $serialized_response = redis->hget($username, "tweets");
    }
  } else {
    $response        = $self->_response($self->_get_user_timeline_url($username));
    $parsed_response = from_json($response->content);

    my @tweets = map { Models::Tweet->new($_) } @$parsed_response;

    $serialized_response = to_json({ tweets => \@tweets });

    redis->hmset($username,
      "request_date" => $response->header('Date'),
      "tweets" => $serialized_response,
    );
  }

  return $serialized_response;
}

# Private Methods
sub _response {
  my ($self, $path) = @_;
  return $self->_request->get($path);
}

sub _request {
  my $self = shift;
  my $user_agent = LWP::UserAgent->new;

  $user_agent->default_header('Authorization' => "Bearer " . $self->_bearer_token);

  return $user_agent;
}

sub _bearer_token {
  return Services::TwitterClient::Authentication->new->get_bearer_token;
}

sub _get_user_timeline_url {
  my ($self, $username) = @_;
  return $self->base_uri . 'statuses/user_timeline.json' . "?screen_name=$username&count=10&trim_user=true";
}

sub _get_friends_ids_url {
  my $self = shift;
  return $self->base_uri . 'friends/ids.json';
}

sub _get_users_lookup_url {
  my $self = shift;
  return $self->base_uri . 'users/lookup.json';
}

 __PACKAGE__->meta->make_immutable;

1;
