package LifeBoard::Schema::Day;

use Moose;
use DateTime;

use namespace::autoclean;

has name => (
    isa         => 'Str',
    is          => 'ro',
    required    => 1
);

has year => (
    isa         => 'LifeBoard::Schema::Year',
    is          => 'ro',
    required    => 1,
);

has month => (
    isa         => 'LifeBoard::Schema::Month',
    is          => 'ro',
    required    => 1,
);

has notes => (
    isa         => 'ArrayRef[LifeBoard::Schema::Note]',
    is          => 'ro',
    default     => sub { [ ] },
    traits      => [ 'Array' ],
    handles     => {
        'has_notes'    => 'count',
        'all_notes'    => 'elements',
        'push_note'    => 'push',
    }
);

sub add_note {
    my ( $self, $note ) = @_;

    $note->day( $self );
    $self->push_note( $note );
}

no Moose;
__PACKAGE__->meta->make_immutable;
