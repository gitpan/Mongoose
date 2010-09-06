package Mongoose::Meta::AttributeTraits;
BEGIN {
  $Mongoose::Meta::AttributeTraits::VERSION = '0.04';
}

package Mongoose::Meta::Attribute::Trait::Binary;
BEGIN {
  $Mongoose::Meta::Attribute::Trait::Binary::VERSION = '0.04';
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
  $Moose::Meta::Attribute::Custom::Trait::Binary::VERSION = '0.04';
}
	sub register_implementation {'Mongoose::Meta::Attribute::Trait::Binary'}
}

# -----------------------------------------------------------------

package Mongoose::Meta::Attribute::Trait::DoNotSerialize;
BEGIN {
  $Mongoose::Meta::Attribute::Trait::DoNotSerialize::VERSION = '0.04';
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
  $Moose::Meta::Attribute::Custom::Trait::DoNotSerialize::VERSION = '0.04';
}
	sub register_implementation {'Mongoose::Meta::Attribute::Trait::DoNotSerialize'}
}

# -----------------------------------------------------------------

{
	package Mongoose::Meta::Attribute::Trait::Raw;
BEGIN {
  $Mongoose::Meta::Attribute::Trait::Raw::VERSION = '0.04';
}
	use strict;
	use Moose::Role;
}
{
	package Moose::Meta::Attribute::Custom::Trait::Raw;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::Raw::VERSION = '0.04';
}
	sub register_implementation {'Mongoose::Meta::Attribute::Trait::Raw'}
}

#package Moose::Meta::Attribute::Custom::DoNotSerialize;
#use Moose::Role;

#package Moose::Meta::Attribute::Custom::Trait::PrimaryKey;
#use Moose::Role;

=head1 NAME

Mongoose::Meta::AttributeTraits - Mongoose related attribute traits

=head1 VERSION

version 0.04

=head1 DESCRIPTION

All Moose attribute traits used by Mongoose are defined here.

=head2 DoNotSerialize

Makes Mongoose skip collapsing or expanding the attribute.

=head2 Raw

Skips unblessing of an attribute when saving an object. 

=cut

1;