package Mongoose::Role::Engine;
$Mongoose::Role::Engine::VERSION = '0.26';
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

version 0.26

=head1 DESCRIPTION

The engine role. No moving parts. Required by any engine wannabees. 

=cut 

1;
