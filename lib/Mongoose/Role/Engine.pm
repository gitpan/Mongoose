package Mongoose::Role::Engine;
BEGIN {
  $Mongoose::Role::Engine::VERSION = '0.01_02';
}
use Moose::Role;

requires 'save';
requires 'delete';
requires 'find';
requires 'find_one';
requires 'query';
requires 'collection';

=head1 NAME

Mongoose::Role::Engine

=head1 VERSION

version 0.01_02

=head1 DESCRIPTION

The engine role. No moving parts. Required by any engine wannabees. 

=cut 

1;