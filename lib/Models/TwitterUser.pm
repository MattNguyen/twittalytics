package Models::TwitterUser;

use Moose;
use namespace::autoclean;

has "id"                => (isa => 'Str', is => 'rw');
has "name"              => (isa => 'Str', is => 'rw');
has "screen_name"       => (isa => 'Str', is => 'rw');
has "profile_image_url" => (isa => 'Str', is => 'rw');
has "description"       => (isa => 'Str', is => 'rw');
has "created_at"        => (isa => 'Str', is => 'rw');

sub TO_JSON {
  my $self = shift;

  return {
    "id"                => $self->id,
    "name"              => $self->name,
    "screen_name"       => $self->screen_name,
    "profile_image_url" => $self->profile_image_url,
    "description"       => $self->description,
    "created_at"        => $self->created_at,
  };
}

 __PACKAGE__->meta->make_immutable;

1;
