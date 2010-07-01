package LifeBoard::Web::Model::KiokuDB;

use Moose;

use LifeBoard::Model::KiokuDB;

BEGIN { extends 'Catalyst::Model::KiokuDB'; }

has '+model_class' => (
    default => 'LifeBoard::Model::KiokuDB'
);

no Moose;
__PACKAGE__->meta->make_immutable;

