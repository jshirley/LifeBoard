package LifeBoard::Schema::Note;

use Moose;
use MooseX::Types::DateTime qw(DateTime);
use URI;

use namespace::autoclean;

use LifeBoard::Schema::Day;

with 'KiokuDB::Role::UUIDs', 'KiokuDB::Role::ID';

sub kiokudb_object_id { shift->id };

has id => (
    isa         => "Str",
    is          => "ro",
    lazy_build  => 1,
    builder     => "generate_uuid"
);

has contents => (
    isa         => 'Str',
    is          => 'rw',
    required    => 1
);

has date => (
    isa         => 'DateTime',
    is          => 'ro',
    coerce      => 1,
    required    => 1
);

has day => (
    isa         => 'LifeBoard::Schema::Day',
    is          => 'rw',
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
