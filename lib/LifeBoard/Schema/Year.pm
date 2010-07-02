package LifeBoard::Schema::Year;

use Moose;

use LifeBoard::Schema::Month;

use namespace::autoclean;

has name => (
    isa         => 'Str',
    is          => 'ro',
    required    => 1
);

has months => (
    isa         => 'ArrayRef[LifeBoard::Schema::Month]',
    is          => 'ro',
    lazy_build  => 1,
    traits      => [ 'Array' ],
    handles     => {
        'get_month_zero' => 'get',
        'all_months'     => 'elements'
    }
);

sub get_month {
    my ( $self, $month ) = @_;
    $self->get_month_zero( $month - 1 );
}

sub _build_months {
    my ( $self ) = @_;

    my @months = ();

    foreach my $month ( 1 .. 12 ) {
        push @months,
            LifeBoard::Schema::Month->new( name => $month, year => $self );
    }

    return \@months;
}

sub add_note {
    my ( $self, $note ) = @_;
    $self->clear_notes;
    $self->get_month( $note->date->month )->add_note( $note );
}

has notes => (
    isa => 'ArrayRef[LifeBoard::Schema::Note]',
    is  => 'ro',
    lazy_build => 1,
    traits => [ 'Array', 'KiokuDB::DoNotSerialize' ],
    handles => {
        'all_notes' => 'elements'
    }
);

sub _build_notes {
    my ( $self ) = @_;
    return [ map { @{ $_->notes } } $self->all_months ];
}


no Moose;
__PACKAGE__->meta->make_immutable;
