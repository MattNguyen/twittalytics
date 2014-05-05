package Models::Tweet;

use Moose;
use namespace::autoclean;
use Data::Dumper;

has "id"         => (isa => 'Str', is => 'rw');
has "text"       => (isa => 'Str', is => 'rw');
has "user"       => (isa => 'Str', is => 'rw');
has "created_at" => (isa => 'Str', is => 'rw');

around "BUILDARGS" => sub {
  my $orig = shift;
  my $class = shift;
  my $params = $_;

  # Set User to user_id if user params is a hash
  if (ref $params->{user} eq ref {}) {
    $params->{user} = $params->{user}->{id};
  }

  return $class->$orig($params);
};

sub TO_JSON {
  my $self = shift;

  return {
    id         => $self->id,
    text       => $self->text,
    user       => $self->user,
    created_at => $self->created_at,
  };
}

 __PACKAGE__->meta->make_immutable;

1;
