package LifeBoard::Schema::Person;

use Moose;

with 'KiokuX::User';

use KiokuDB::Set;
use KiokuDB::Util qw(set);

use LifeBoard::Schema::Note;

use namespace::autoclean;

has name => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has friends => (
    isa     => 'KiokuDB::Set',
    is      => 'ro',
    lazy    => 1,
    default => sub { set() }
);

has 'notes' => (
    isa     => 'KiokuDB::Set',
    is      => 'ro',
    lazy    => 1,
    default => sub { set() }
);

sub add_note {
    my ( $self, @args ) = @_;

    my $note = LifeBoard::Schema::Note->new(
        owner => $self,
        @args
    );

    $self->notes->insert( $note );

    return $note;
}

no Moose;
__PACKAGE__->meta->make_immutable;

