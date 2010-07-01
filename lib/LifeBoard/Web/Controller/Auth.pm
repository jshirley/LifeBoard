package LifeBoard::Web::Controller::Auth;

use Moose;
use namespace::autoclean;

use Data::Verifier;
use KiokuX::User::Util 'crypt_password';
use Try::Tiny;
use DateTime;

use LifeBoard::Schema::Person;

BEGIN { extends 'Catalyst::Controller' }

sub setup : Chained('/') PathPart('') CaptureArgs(0) { 
    my ( $self, $c ) = @_;
    $c->stash->{now} =  DateTime->now;
}

sub logout : Chained('setup') Args(0) {
    my ( $self, $c ) = @_;
    $c->message("You are logged out.  Bye ;(");
    $c->logout;
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

sub register : Chained('setup') Args(0) {
    my ( $self, $c ) = @_;

    unless ( $c->req->method eq 'POST' ) {
        $c->res->redirect( $c->uri_for_action('/auth/login') );
        $c->detach;
    }

    my $db   = $c->model('KiokuDB');
    my $data = $c->req->params;

    my $verifier = Data::Verifier->new(
        filters => [ 'trim' ],
        profile => {
            id => {
                required => 1,
                type     => 'Str',
                min_length => 2,
                post_check => sub {
                    my $r = shift;
                    my $id_str = join(':', 'user', $r->get_value('id'));
                    return !$db->exists( $id_str );
                }
            },
            name => {
                required => 1,
                type     => 'Str',
                min_length => 2,
            },
            password => {
                required   => 1,
                type       => 'Str',
                min_length => 4,
                dependent => {
                    password_confirm => {
                        required => 1,
                    }
                },
                post_check => sub {
                    my $r = shift;
                    $r->get_value('password') eq $r->get_value('password_confirm');
                }
            }
        }
    );

    my $results = $verifier->verify( $data->{register} );
    unless ( $results->success ) {
        $c->message({
            type => 'error',
            message => $c->loc("Please correct the errors below.")
        });
        $c->flash->{errors}->{register} = $results;
        $c->res->redirect( $c->uri_for_action('/auth/login') );
        $c->detach;
    }

    my %args = (
        id       => $results->get_value('id'),
        name     => $results->get_value('name'),
        password => crypt_password($results->get_value('password')),
    );
    my $person = LifeBoard::Schema::Person->new( %args );
    $db->store( $person );
    $c->message($c->loc('Thank you for registering, you are ready to go'));
    $db->store( $person );
    $c->res->redirect( $c->uri_for_action('/auth/login') );
}

no Moose;
__PACKAGE__->meta->make_immutable;
