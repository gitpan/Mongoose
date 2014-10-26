  package Address;
  use Moose;
  use Moose::Util::TypeConstraints;
  with 'EmbeddedDocument';

  use Locale::US;
  use Regexp::Common 'zip';

  my $STATES = Locale::US->new;
  subtype 'USState'
      => as Str
      => where {
             (    exists $STATES->{code2state}{ uc($_) }
               || exists $STATES->{state2code}{ uc($_) } );
         };

  subtype 'USZipCode'
      => as Value
      => where {
             /^$RE{zip}{US}{-extended => 'allow'}$/;
         };

  has 'street'   => ( is => 'rw', isa => 'Str' );
  has 'city'     => ( is => 'rw', isa => 'Str' );
  has 'state'    => ( is => 'rw', isa => 'USState' );
  has 'zip_code' => ( is => 'rw', isa => 'USZipCode' );

  package Company;
  use Moose;
  use Moose::Util::TypeConstraints;
  with 'Document';

  has 'name' => ( is => 'rw', isa => 'Str', required => 1 );
  has 'address'   => ( is => 'rw', isa => 'Address' );
  has 'employees' => ( is => 'rw', isa => 'ArrayRef[Employee]' );

  sub BUILD {
      my ( $self, $params ) = @_;
      foreach my $employee ( @{ $self->employees || [] } ) {
          $employee->employer($self);
      }
  }

  after 'employees' => sub {
      my ( $self, $employees ) = @_;
      foreach my $employee ( @{ $employees || [] } ) {
          $employee->employer($self);
      }
  };

  package Person;
  use Moose;
  with 'Document';

  has 'first_name' => ( is => 'rw', isa => 'Str', required => 1 );
  has 'last_name'  => ( is => 'rw', isa => 'Str', required => 1 );
  has 'middle_initial' => (
      is        => 'rw', isa => 'Str',
      predicate => 'has_middle_initial'
  );
  has 'address' => ( is => 'rw', isa => 'Address' );

  sub full_name {
      my $self = shift;
      return $self->first_name
          . (
          $self->has_middle_initial
          ? ' ' . $self->middle_initial . '. '
          : ' '
          ) . $self->last_name;
  }

  package Employee;
  use Moose;
  with 'Document';

  extends 'Person';

  has 'title'    => ( is => 'rw', isa => 'Str',     required => 1 );
  has 'employer' => ( is => 'rw', isa => 'Company', weak_ref => 1 );

  override 'full_name' => sub {
      my $self = shift;
      super() . ', ' . $self->title;
  };


package main;
use v5.10;
use MooseX::Mongo;
use Benchmark;
my $db = MooseX::Mongo->db( 'mediadb' );
sub cleanup {
	$db->run_command({ drop => 'address' });
	$db->run_command({ drop => 'company' });
	$db->run_command({ drop => 'person' });
	$db->run_command({ drop => 'employee' });
}
cleanup();
{
	my $address = new Address( street=>'1st st. 212', city=>'Gotham', zip_code=>'12345', state=>'NY'  );
	my $company = new Company( name=> 'Acme', address=>$address );
	my $employee = new Employee( first_name=>'John', last_name=>'Doe', title=>'CEO');
	$company->employees([ $employee ]);
	timethis( 1000, sub { $company->save; });
	say $company->dump
}
{
	my $rs = Company->find;
	while ( my $c = $rs->next ) {
		say $c->dump;
		#say $c->address->dump;
		#$c->address->save;
		#$c->save;
	}


}
