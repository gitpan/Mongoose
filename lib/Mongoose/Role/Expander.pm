package Mongoose::Role::Expander;
BEGIN {
  $Mongoose::Role::Expander::VERSION = '0.04';
}
use Moose::Role;

requires 'expand';

=head1 NAME

Mongoose::Role::Expander

=head1 VERSION

version 0.04

=head1 DESCRIPTION

The expander role. No moving parts. Used by the engine. 

=cut 

1;