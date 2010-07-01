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
    $c->model('KiokuDB')->store( $person );

    @notes = $person->notes->members;
    @notes = grep { $_->date->ymd eq $date->ymd } @notes;
    
    my @ids = $c->model('KiokuDB')->directory->objects_to_ids( @notes );
    $c->stash->{notes}->{$date->ymd} = [];
    foreach my $note ( @notes ) {
        $c->log->debug("Adding note: $ids[0], note: " . $note->contents);
        push @{ $c->stash->{notes}->{$date->ymd} },
            { note => $note, id => shift @ids };
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

    my $person = $c->model('KiokuDB')->lookup( $c->user->get_object->kiokudb_object_id );
    my $note   = $c->stash->{note};

    $c->stash->{day} = $date;

    #$note->date( $data->{date} );
    $note->contents( $data->{note} );

    $c->model('KiokuDB')->update( $note );

    my @notes = 
        grep { $_->date->ymd eq $date->ymd }
        $person->notes->members;
    
    my @ids = $c->model('KiokuDB')->directory->objects_to_ids( @notes );
    $c->stash->{notes}->{$date->ymd} = [];
    foreach my $note ( @notes ) {
        push @{ $c->stash->{notes}->{$date->ymd} },
            { note => $note, id => shift @ids };
    }

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
