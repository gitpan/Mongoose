package Mongoose::Role::Collapser;
BEGIN {
  $Mongoose::Role::Collapser::VERSION = '0.07';
}
use Moose::Role;

requires 'collapse';

=head1 NAME

Mongoose::Role::Collapser

=head1 VERSION

version 0.07

=head1 DESCRIPTION

The collapser role. No moving parts. Used by the engine. 

=cut 

1;