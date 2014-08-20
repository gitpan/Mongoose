use v5.10;

package Foo;
use Moose;

has xx => qw(is rw isa Str);

package Bar;
use Moose;

has aa => qw(is rw isa ArrayRef[Foo]);

package main;

my $doc = {
    aa => [ { xx => 10 } ]
};
