package Mongoose::Role::Expander;
BEGIN {
  $Mongoose::Role::Expander::VERSION = '0.01_02';
}
use Moose::Role;

requires 'expand';

=head1 NAME

Mongoose::Role::Expander

=head1 VERSION

version 0.01_02

=head1 DESCRIPTION

The expander role. No moving parts. Used by the engine. 

=cut 

1;