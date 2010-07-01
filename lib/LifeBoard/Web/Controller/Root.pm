package LifeBoard::Web::Controller::Root;

use Moose;
use namespace::autoclean;

use Message::Stack;
use Message::Stack::DataVerifier;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

LifeBoard::Web::Controller::Root - Root Controller for LifeBoard::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub setup : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( defined ( my $errors = $c->flash->{errors} ) ) {
        my $stack = $c->stash->{messages} || Message::Stack->new;

        foreach my $scope ( keys %{ $errors } ) {
            $c->log->debug("Fetching errors for scope: $scope");
            $c->stash->{results}->{$scope} = $errors->{$scope};
            Message::Stack::DataVerifier->parse( $stack, $scope, $errors->{$scope} );
        }
        $c->stash->{stack}      = $stack;
        $c->stash->{messages} ||= $stack;
    }

    unless ( $c->user_exists ) {
        $c->res->redirect( $c->uri_for_action('/auth/login') );
        $c->detach;
    }
}

sub root : Chained('setup') PathPart('') Args(0) { 
    my ( $self, $c ) = @_;

    $c->res->redirect( $c->uri_for_action('/calendar/root') );
}

sub calendar : Chained('setup') PathPart('') CaptureArgs(0) { }

=head2 default

Standard 404 error page

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Jay Shirley

=cut

__PACKAGE__->meta->make_immutable;

1;
