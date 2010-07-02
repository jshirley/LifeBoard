package LifeBoard::Schema::Month;

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

has days => (
    isa         => 'ArrayRef[LifeBoard::Schema::Day]',
    is          => 'ro',
    lazy_build  => 1,
    traits      => [ 'Array' ],
    handles     => {
        'get_day_zero'  => 'get',
        'all_days'      => 'elements',
    }
);

sub get_day {
    my ( $self, $day ) = @_;
    $self->get_day_zero( $day - 1 );
}

sub _build_days {
    my ( $self ) = @_;

    my @months = ();
    my $ldom = DateTime->last_day_of_month(
        month => $self->name,
        year  => $self->year->name
    );

    my @days;
    foreach my $day ( 1 .. $ldom->day ) {
        push @days,
            LifeBoard::Schema::Day->new(
                name => $day, year => $self->year, month => $self
            );
    }

    return \@days;
}

sub add_note {
    my ( $self, $note ) = @_;

    $self->clear_notes;
    $self->get_day( $note->date->day )->add_note( $note );
}

has notes => (
    isa         => 'ArrayRef[LifeBoard::Schema::Note]',
    is          => 'ro',
    lazy_build  => 1,
    traits      => [ 'Array', 'KiokuDB::DoNotSerialize' ],
    handles => {
        'all_notes' => 'elements'
    }
);

sub _build_notes {
    my ( $self ) = @_;
    return [ map { $_->all_notes; } $self->all_days ];
}

no Moose;
__PACKAGE__->meta->make_immutable;
