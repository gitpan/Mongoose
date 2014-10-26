package Mongoose;
BEGIN {
  $Mongoose::VERSION = '0.01_02';
}
use MongoDB;
use MooseX::Singleton;
use Mongoose::Join;
use Mongoose::Meta::AttributeTraits;

has '_db' => ( is => 'rw', isa => 'HashRef[MongoDB::Database]' );

has 'connection' => (
    is      => 'rw',
    isa     => 'MongoDB::Connection',
);
has 'naming' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub {
			my $n=shift;
			$n =~ s{([a-z])([A-Z])}{$1_$2}g;
			$n =~ s{\:\:}{_}g;
			lc($n);
		}
    }
);

sub db { 
	my $self = shift;
	my $key = 'default';
	if( scalar(@_)==1 && defined $_[0] ) {
     	$self->connection( MongoDB::Connection->new );
		$self->_db({ $key => $self->connection->get_database( $_[0] ) })
	}
	elsif( scalar(@_)>2 ) {
		my %p = @_;
		$key = delete($p{class}) || $key;
		$self->connection( MongoDB::Connection->new( @_ ) ) 
			unless ref $self->connection;
		$self->_db({ $key => $self->connection->get_database( $p{db_name} ) })
	}
	return $self->_db->{default};
}

sub _db_for_class {
	my ($self, $class) = @_;
	return $self->_db->{$class} || $self->_db->{default};
}

1;

=head1 NAME

Mongoose - MongoDB document to Moose object mapper

=head1 VERSION

version 0.01_02

=head1 SYNOPSIS

	package Person;
	use Moose;
	with 'Mongoose::Document';
	has 'name' => ( is=>'rw', isa=>'Str' );

	package main;
	use Mongoose;

    Mongoose->db( 'mydb' ); 
	my $person = Person->new( name=>'Jack' );
	$person->save;

	my $person = Person->find_one({ name=>'Jack' });
    say $person->name; # Jack

	my $cursor = Person->find({ name=>'Jack' });
	die "Not found" unless defined $cursor;
	while( my $person = $cursor->next ) {
		say "You're " . $person->name;	
	}

	$person->delete;

=head1 DESCRIPTION

This is a MongoDB to Moose object mapper. This module allows you to use the full
power of MongoDB within your Moose classes, without sacrificing MongoDB's
power, flexibility and speed.

It's loosely inspired by Ruby's MongoMapper,
which is in turn based on the ActiveRecord pattern. 

Start by reading the introduction L<Mongoose::Intro>. 

Or proceed directly to the L<Mongoose::Cookbook> for many day-to-day recipies.

=head1 METHODS

=head2 db

Sets the current MongoDB connection and/or db name. 

	Mongoose->db( 'myappdb' );

The connection defaults to whatever MongoDB defaults are
(tipically localhost:27017).

For more control over the connection, C<db> takes the same parameters as
L<MongoDB::Connection>, plus C<db_name>. 

	my $db = Mongoose->db(
		host          => 'mongodb://localhost:27017',
		query_timeout => 60,
		db_name       => 'myapp' 
	);

This will, in turn, instantiate a C<MongoDB::Connection> instance
with all given parameters. 

=head2 naming 

By default, Mongoose converts package names into collections by replacing
double-colon C<::> with underscores C<_>, separating camel-case,
such as C<aB> with C<a_b> and uppercase with lowercase letters. 

This method let's you change this behaviour, by setting
setting the collection naming default sub. 

The closure receives the package name as first parameter and 
should return the collection name. 

	# let me change the naming strategy
	#  for my mongo collections
	#  to plain lowercase 
	Mongoose->naming(sub{ lc( shift ) }); 

=head2 connection

Sets/returns the current connection object, of class L<MongoDB::Connection>.

Defaults to whatever MongoDB defaults.

=head1 REPOSITORY

Fork me on github: L<http://github.com/rodrigolive/mongoose>

=head1 BUGS

This is a WIP, barely *beta* quality software. 

Report bugs via RT. Send me test cases.

=head1 TODO

* Better error control

* Finish-up multiple database support

* Allow query->fields to control which fields get expanded into the object. 

* Cleanup internals.

* More tests and use cases.

* Better documentation.

=head1 SEE ALSO

L<KiokuDB>