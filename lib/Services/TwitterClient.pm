package Services::TwitterClient;

use Dancer ':syntax';
use Moose;
use namespace::autoclean;
use Cwd 'realpath';
use Data::Dumper;

use Services::TwitterClient::API;

sub get_statuses_for_user {
  my ($self, $username) = @_;
  return Services::TwitterClient::API->new->get_statuses_for_user($username);
}

sub get_common_friends {
  my ($self, $username1, $username2) = @_;
  return Services::TwitterClient::API->new->get_common_friends($username1, $username2);
}

1;
