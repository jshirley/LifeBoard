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
        $now->set_time_zone( 'America/Los_Angeles' );
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
        $person->get_calendar( $req_day->year )
               ->get_month( $req_day->month )
               ->all_notes;
$c->log->debug("Got " . scalar(@notes) . " notes");
    $c->stash->{notes} = {};
    foreach my $note ( @notes ) {
        $c->log->debug("Note: " . $note->contents);
        $c->stash->{notes}->{$note->date->ymd} ||= [];
        push @{ $c->stash->{notes}->{$note->date->ymd} }, $note;
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
