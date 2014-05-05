package Services::TwitterClient;

use Moose;
use namespace::autoclean;

use Services::TwitterClient::Authentication;

sub fetch_bearer_token {
  return Services::TwitterClient::Authentication->new->fetch_bearer_token;
}

# Helpers ???
sub query_string_for {
  my ( $self, $args ) = @_;

  my @pairs;
  while ( my ($k, $v) = each %$args ) {
    push @pairs, join '=', map URI::Escape::uri_escape_utf8($_,'^\w.~-'), $k, $v;
  }

  return join '&', @pairs;
}

sub encode_args {
  my ($self, $args) = @_;

  return { map { utf8::upgrade($_) unless ref($_); $_ } %$args };
}

 __PACKAGE__->meta->make_immutable;

1;
