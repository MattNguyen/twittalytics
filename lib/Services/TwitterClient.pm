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

1;
