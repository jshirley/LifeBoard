package LifeBoard::Web::Controller::Calendar;

use Moose;
use namespace::autoclean;

use DateTime;
use DateTime::Duration;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub setup : Chained('.') PathPart('calendar') CaptureArgs(0) { }

sub root : Chained('setup') PathPart('') Args() {
    my ( $self, $c, $year, $month ) = @_;

    my $person  = $c->user->get_object;
    my $now     = DateTime->now;
    my $req_day = $now->clone;

    if ( $year && $month ) {
        $req_day->set_year($year);
        $req_day->set_month($month);
        $req_day->set_day(1);
    }
    $c->stash->{now}     = $now;
    $c->stash->{req_day} = $req_day;

    my $ldom = DateTime->last_day_of_month(
        month => $req_day->month,
        year  => $req_day->year
    );
    my $fdom = $ldom->clone->subtract_duration(
        DateTime::Duration->new( months => 1)
    );
    $fdom->add({ days => 1 });
    my @notes = 
        grep { $_->date > $fdom && $_->date < $ldom }
        $person->notes->members;
    $c->stash->{notes} = {};
    my @ids = $c->model('KiokuDB')->directory->objects_to_ids( @notes );
    foreach my $note ( @notes ) {
        $c->stash->{notes}->{$note->date->ymd} ||= [];
        push @{ $c->stash->{notes}->{$note->date->ymd} },
            { note => $note, id => shift @ids };
    }

    my @days = ();
    if($fdom->day_of_week != 7) {

        my $prev_day = $fdom->clone->subtract_duration(
            DateTime::Duration->new(days => 1)
        );
        my $currday = $prev_day;
        push(@days, $currday);
        while($currday->day_of_week != 7) {
            $currday = $currday->clone->subtract_duration(
                DateTime::Duration->new( days => 1)
            );
            push(@days, $currday);
        }
        # Reverse the days, since we counted back.
        @days = reverse(@days);
        $c->stash->{prev_day} = $prev_day;
    }

    my $currday = $fdom;
    $c->stash->{first_day} = $fdom;
    while($currday->day != $ldom->day) {
        push(@days, $currday);
        $currday = $currday->clone->add_duration(
            DateTime::Duration->new( days => 1 )
        );
    }
    push(@days, $ldom);

    $c->stash->{next_day} = $ldom->clone->add_duration(
        DateTime::Duration->new(days => 1)
    );
    if($ldom->day_of_week != 6) {
        my $currday = $c->stash->{next_day};
        while($currday->day_of_week != 7) {
            push(@days, $currday);
            $currday = $currday->clone->add_duration(
                DateTime::Duration->new( days => 1 )
            );
        }
    }

    $c->stash->{days} = \@days;
}

sub day : Chained('setup') PathPart('day') Args(0) { }

sub note : Chained('setup') PathPart('') CaptureArgs(0) { }

no Moose;
__PACKAGE__->meta->make_immutable;
