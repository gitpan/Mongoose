package Mongoose::Meta::Attribute::Trait::Binary;
BEGIN {
  $Mongoose::Meta::Attribute::Trait::Binary::VERSION = '0.01_01';
}
use strict;
use Moose::Role;

has 'column' => (
    isa             => 'Str',
    is              => 'rw',
);

has 'lazy_select' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 0,
);

# -----------------------------------------------------------------

{
	package Moose::Meta::Attribute::Custom::Trait::Binary;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::Binary::VERSION = '0.01_01';
}
	sub register_implementation {'Mongoose::Meta::Attribute::Trait::Binary'}
}

# -----------------------------------------------------------------

package Mongoose::Meta::Attribute::Trait::DoNotSerialize;
BEGIN {
  $Mongoose::Meta::Attribute::Trait::DoNotSerialize::VERSION = '0.01_01';
}
use strict;
use Moose::Role;

has 'column' => (
    isa             => 'Str',
    is              => 'rw',
);

has 'lazy_select' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 0,
);

# -----------------------------------------------------------------

{
	package Moose::Meta::Attribute::Custom::Trait::DoNotSerialize;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::DoNotSerialize::VERSION = '0.01_01';
}
	sub register_implementation {'Mongoose::Meta::Attribute::Trait::DoNotSerialize'}
}

#package Moose::Meta::Attribute::Custom::DoNotSerialize;
#use Moose::Role;

#package Moose::Meta::Attribute::Custom::Trait::PrimaryKey;
#use Moose::Role;

=head1 NAME

Mongoose::Meta::AttributeTraits

=head1 VERSION

version 0.01_01

=head1 DESCRIPTION

All Moose attribute traits used by Mongoose are defined here.

=cut

1;