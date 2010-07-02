package LifeBoard::Web::Controller::Calendar::Note;

use Moose;
use namespace::autoclean;

use DateTime;
use DateTime::Duration;
use DateTime::Format::SQLite;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller::REST' }

sub setup : Chained('.') PathPart('note') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{now} = DateTime->now;
        $c->stash->{now}->set_time_zone( 'America/Los_Angeles' );
    $c->stash->{page}->{layout} = 'partial';
}

sub root : Chained('setup') PathPart('') Args(0) ActionClass('REST') { }

sub root_POST {
    my ( $self, $c ) = @_;

    my $data = $c->req->data || $c->req->params;
    $c->log->_dump( $data );

    my $person = $c->model('KiokuDB')->lookup( $c->user->get_object->kiokudb_object_id );

    my $date = $data->{date} ?
        DateTime::Format::SQLite->parse_date( $data->{date} ) :
        DateTime->now;

    $c->stash->{day} = $date;

    my @notes;

    my $note = $person->add_note(
        date     => $date,
        contents => $data->{note}
    );
    # Update the note
    $c->model('KiokuDB')->insert( $note );
    $c->model('KiokuDB')->update( $note->day );

    my @notes =
        $person->get_calendar( $date->year )
               ->get_month( $date->month )
               ->get_day( $date->day )
               ->all_notes;
    $c->stash->{notes} = {};
    foreach my $note ( @notes ) {
        $c->stash->{notes}->{$note->date->ymd} ||= [];
        push @{ $c->stash->{notes}->{$note->date->ymd} }, $note;
    }

    $self->status_ok(
        $c,
        entity => {
            message => "The note has been added",
            markup  => $c->view('TT')->render($c, 'calendar/day.tt')
        }
    );
}

sub object_setup : Chained('setup') PathPart('') CaptureArgs(1) { 
    my ( $self, $c, $id ) = @_;

    my $obj = $c->model('KiokuDB')->lookup( $id );
    $c->stash->{note} = $obj;
}

sub object : Chained('object_setup') PathPart('') Args(0) ActionClass('REST') { }

sub object_POST {
    my ( $self, $c ) = @_;

    my $data = $c->req->data || $c->req->params;

    my $date = $data->{date} ?
        DateTime::Format::SQLite->parse_date( $data->{date} ) :
        DateTime->now;

    my $person = $c->user->get_object;
    my $note   = $c->stash->{note};

    $c->stash->{day} = $date;

    #$note->date( $data->{date} );
    $note->contents( $data->{note} );

    $c->model('KiokuDB')->update( $note );

    my @notes =
        $person->get_calendar( $date->year )
               ->get_month( $date->month )
               ->get_day( $date->day )
               ->all_notes;
    $c->stash->{notes} = {};
    foreach my $note ( @notes ) {
        $c->stash->{notes}->{$note->date->ymd} ||= [];
        push @{ $c->stash->{notes}->{$note->date->ymd} }, $note;
    }

    $self->status_ok(
        $c,
        entity => {
            message => "The note has been added",
            markup  => $c->view('TT')->render($c, 'calendar/day.tt')
        }
    );

}

sub object_DELETE {
    my ( $self, $c ) = @_;

    my $person = $c->model('KiokuDB')->lookup( $c->user->get_object->kiokudb_object_id );
    my $note   = $c->stash->{note};
    my $date   = $note->date;

    $person->notes->remove( $note );
    $c->model('KiokuDB')->update( $person->notes );
    $c->model('KiokuDB')->delete( $note );
    $note = undef;

    my @notes = 
        grep { $_->date->ymd eq $date->ymd }
        $person->notes->members;
    
    my @ids = $c->model('KiokuDB')->directory->objects_to_ids( @notes );
    $c->stash->{notes}->{$date->ymd} = [];
    foreach my $note ( @notes ) {
        push @{ $c->stash->{notes}->{$date->ymd} },
            { note => $note, id => shift @ids };
    }

    $c->stash->{day} = $date;
    $self->status_ok(
        $c,
        entity => {
            message => "The note has been added",
            markup  => $c->view('TT')->render($c, 'calendar/day.tt')
        }
    );


}

no Moose;
__PACKAGE__->meta->make_immutable;
