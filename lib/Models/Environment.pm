package Models::Environment;

use Moose;
use namespace::autoclean;

# Source .env file
BEGIN {
  if ($ENV{'ENVIRONMENT'} eq 'development') {
    open(my $fh, "<", ".env") || die "Could not open .env: $!";

    while (<$fh>) {
      chomp;
      my ($k, $v) = split /=/, $_, 2;
      $ENV{$k} = $v;
    }
  }

  die("Please set TWITTER_API_KEY in your .env file") unless $ENV{"TWITTER_API_KEY"};
  die("Please set TWITTER_API_SECRET in your .env file") unless $ENV{"TWITTER_API_SECRET"};
}

has 'twitter_api_key'    => (isa => 'Str', is => 'ro', default => $ENV{"TWITTER_API_KEY"});
has 'twitter_api_secret' => (isa => 'Str', is => 'ro', default => $ENV{"TWITTER_API_SECRET"});

__PACKAGE__->meta->make_immutable;

1;
