package App::AngryFruitSalad::Model::RDF;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::RDF';

=head1 NAME

App::AngryFruitSalad::Model::RDF - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
