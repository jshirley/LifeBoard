package LifeBoard::Model::KiokuDB;

use Moose;

extends 'KiokuX::Model';

sub insert_person {
    my ( $self, $person ) = @_;

    my $id = $self->txn_do( sub {
        $self->store( $person );
    });
}

no Moose;
__PACKAGE__->meta->make_immutable;
