package Services::TwitterClient::API;

use Dancer ':syntax';
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Services::TwitterClient::Authentication;
use Dancer::Plugin::Redis;
use Models::Tweet;
use Models::TwitterUser;
use HTTP::Date;
use Array::Utils qw(:all);
use LWP::Protocol::https;
use Mozilla::CA;

has 'base_uri' => (isa => 'Str', is => 'ro', default => 'https://api.twitter.com/1.1/');

sub get_statuses_for_user {
  my ($self, $username) = @_;
  my $response;
  my $parsed_response;
  my $serialized_response;

  # TODO - For the love of god, fix this monstrosity. -MN 05102014
  if (redis->hexists($username, "request_date")) {
    info "Username '$username' found in cache.";

    my $ttl = 60;
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

      $response = $self->_response($self->_get_user_timeline_url($username));
      if ($response->is_success) {
        my @new_tweets                 = map { Models::Tweet->new($_) } @{ from_json($response->content) };
        my @deserialized_cached_tweets = @{ from_json($cached_tweets)->{tweets} };
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
          "tweets"       => $serialized_response,
        );
      } else {
        $serialized_response = $self->_format_error($response);
      }
    } else {
      info "Data under TTL threshold. Using cached tweets.";
      $serialized_response = redis->hget($username, "tweets");
    }
  } else {
    $response = $self->_response($self->_get_user_timeline_url($username));
    if ($response->is_success) {
      my @tweets = map { Models::Tweet->new($_) } @{ from_json($response->content) };

      $serialized_response = to_json({ tweets => \@tweets });

      redis->hmset($username,
        "request_date" => $response->header('Date'),
        "tweets"       => $serialized_response,
      );
     } else {
       $serialized_response = to_json({
           error  => $response->status_line,
           status => $response->code,
       });
     }
  }

  return $serialized_response;
}

sub get_common_friends {
  my ($self, $username1, $username2) = @_;
  my $ttl = 60;
  my $intersection_key = $self->_intersection_key($username1, $username2);
  my $serialized_response;

  # TODO - figure out api pagination. -MN 05102014
  # * getting friend_ids has cursor ids to page back and forth
  # * ids are different depending on user
  # * endpoint should direct requsts with pagination params to some other function that continues the pagination chain to twitter
  if (redis->hexists($intersection_key, 'request_date')) {
    info "$intersection_key found in cache";
    my $request_date = str2time(redis->hget($intersection_key, 'request_date'));
    my $current_date = str2time(scalar localtime);

    if ($current_date > ($request_date + $ttl)) {
      info "Data over TTL time. Renewing stale data...";

      $serialized_response = $self->_get_intersection_results($username1, $username2);
    } else {
      info "Data under TTL threshold. Using cached intersection data.";

      $serialized_response = redis->hget($intersection_key, "common_friends");
    }
  } else {
    $serialized_response = $self->_get_intersection_results($username1, $username2);
  }

  return $serialized_response;
}

# Private Methods
sub _get_intersection_results {
  my ($self, $username1, $username2) = @_;
  my $serialized_response;

  # Get list of friend ids for username1
  my $user1_follow_response = $self->_response($self->_get_friends_ids_url($username1));
  if ($user1_follow_response->is_success) {
    my $deserialized_user1_follow_response = from_json($user1_follow_response->content);
    redis->hmset($username1 . "_friend_ids",
      "request_date"    => $user1_follow_response->header('date'),
      "ids"             => to_json($deserialized_user1_follow_response->{ids}),
      "previous_cursor" => $deserialized_user1_follow_response->{previous_cursor},
      "next_cursor"     => $deserialized_user1_follow_response->{next_cursor},
    );

    # Get list of friend ids for username2
    my $user2_follow_response = $self->_response($self->_get_friends_ids_url($username2));
    if ($user2_follow_response) {
      my $deserialized_user2_follow_response = from_json($user2_follow_response->content);
      redis->hmset($username2 . "_friend_ids",
        "request_date"    => $user2_follow_response->header('Date'),
        "ids"             => to_json($deserialized_user2_follow_response->{ids}),
        "previous_cursor" => $deserialized_user2_follow_response->{previous_cursor},
        "next_cursor"     => $deserialized_user2_follow_response->{next_cursor},
      );

      # Find intersection
      my @user1_follow_ids = @{ $deserialized_user1_follow_response->{ids} };
      my @user2_follow_ids = @{ $deserialized_user2_follow_response->{ids} };
      my @intersection = intersect(@user1_follow_ids, @user2_follow_ids);

      # Get user objects with intersection list
      my $lookup_users_response = $self->_response($self->_get_users_lookup_url($self->_separate_by_commas(@intersection)));
      if ($lookup_users_response->is_success) {
        my $deserialized_lookup_users_response = from_json($lookup_users_response->content);
        my @followed_users = map { Models::TwitterUser->new($_) } @$deserialized_lookup_users_response;
        $serialized_response = to_json({ common_friends => \@followed_users});
        redis->hmset($username1 . "_" . $username2 . "_intersection",
          "request_date" => $lookup_users_response->header('Date'),
          "common_friends" => $serialized_response,
        );
      } else {
        $serialized_response = $self->_format_error($lookup_users_response);
      }
    } else {
      $serialized_response = $self->_format_error($user2_follow_response);
    }

  } else {
    $serialized_response = $self->_format_error($user1_follow_response);
  }

  return $serialized_response;
}

sub _format_error {
  my ($self, $response) = @_;
  return to_json({
           error  => $response->status_line,
           status => $response->code,
         });
}

sub _intersection_key {
  my ($self, $username1, $username2) = @_;
  my $combo1 = redis->hexists($username1 . '_' . $username2 . '_intersection', 'request_date');
  my $combo2 = redis->hexists($username2 . '_' . $username1 . '_intersection', 'request_date');

  if ($combo1) {
    return $username1 . '_' . $username2 . '_intersection';
  } elsif ($combo2) {
    return $username2 . '_' . $username1 . '_intersection';
  } else {
    return 0;
  }
}

sub _response {
  my ($self, $path) = @_;
  return $self->_request->get($path);
}

sub _request {
  my $self = shift;
  my $user_agent = LWP::UserAgent->new;

  $user_agent->ssl_opts(
    verify_hostname => 1,
    SSL_ca_file     => Mozilla::CA::SSL_ca_file,
  );

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
  my ($self, $username) = @_;
  return $self->base_uri . 'friends/ids.json' . "?screen_name=$username&count=5000";
}

sub _get_users_lookup_url {
  my ($self, $ids) = @_;
  return $self->base_uri . 'users/lookup.json' . "?user_id=$ids&include_entities=false";
}

sub _separate_by_commas {
  my ($self, @array) = @_;
  return join ",", @array;

}
 __PACKAGE__->meta->make_immutable;

1;
