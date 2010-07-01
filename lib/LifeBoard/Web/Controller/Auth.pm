package LifeBoard::Web::Controller::Auth;

use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub setup : Chained('/') PathPart('') CaptureArgs(0) { }

sub logout : Chained('setup') Args(0) {
    my ( $self, $c ) = @_;
    $c->message("You are logged out.  Bye ;(");
    $c->res->redirect( $c->uri_for_action('/auth/login') );
    $c->detach;
}

sub login : Chained('setup') Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->method eq 'POST' ) {
        my $data = $c->req->params->{login} || {};
        my ( $id, $password ) = ( $data->{id}, $data->{password} );
        $c->log->debug("Logging in with $id/$password");
        my $user = eval {
            $c->authenticate({ id => $id, password => $password });
        };

        if ( $user ) {
            $c->res->redirect( $c->uri_for_action('/calendar/root') );
        } else {
            $c->message({
                type => 'error',
                message => "Unable to login, try again."
            });
            $c->res->redirect( $c->uri_for_action('/auth/login') );
        }
        $c->detach;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
