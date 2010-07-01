package LifeBoard::Schema::Note;

use Moose;
use MooseX::Types::DateTime 'DateTime';
use URI;

use namespace::autoclean;

has contents => (
    isa         => 'Str',
    is          => 'rw',
    required    => 1
);

has date => (
    isa         => 'DateTime',
    is          => 'rw',
    coerce      => 1,
    required    => 1,
);

has pictures => (
    is          => 'ro',
    isa         => 'ArrayRef[URI]',
    default     => sub { [ ] },
    traits      => [ 'Array' ],
    handles => {
        'add_picture'   => 'push',
        'all_pictures'  => 'elements',
        'picture_count' => 'count',
        'has_pictures'  => 'count',
    }
);

has owner => (
    isa => 'LifeBoard::Schema::Person',
    is  => 'ro',
    required => 1
);

no Moose;
__PACKAGE__->meta->make_immutable;
