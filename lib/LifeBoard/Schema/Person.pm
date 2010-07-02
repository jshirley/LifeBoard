package LifeBoard::Schema::Person;

use Moose;

with 'KiokuX::User';

use KiokuDB::Set;
use KiokuDB::Util qw(set);

use LifeBoard::Schema::Year;
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

has 'calendars' => (
    isa     => 'HashRef[LifeBoard::Schema::Year]',
    is      => 'ro',
    default => sub { {} },
    traits  => [ 'Hash' ],
    handles => {
        'get_calendar'  => 'get',
        'set_calendar'  => 'set',
        'all_calendars' => 'values',
    }
);

sub add_note {
    my ( $self, %args ) = @_;

    my $date = $args{date};
    die "Must specify date for add_note as a DateTime object"
        unless defined $date and $date->isa('DateTime');

    my $cal = $self->get_calendar($date->year);
    if ( not defined $cal ) {
        $cal = LifeBoard::Schema::Year->new( name => $date->year );
        # XX We should name these? Or create a real calendar object...
        $self->set_calendar( $date->year, $cal );
    }

    my $note = LifeBoard::Schema::Note->new(
        %args,
        owner => $self,
    );

    $cal->add_note( $note );

    return $note;
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
    return [ map { $_->all_notes } $self->all_calendars ];
}

no Moose;
__PACKAGE__->meta->make_immutable;

