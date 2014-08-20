package Person;
use Moose;
with 'Mongoose::Document' => { pk => ['name'], };

has 'name' => ( is=>'rw', isa=>'Str', required=>1 );
has 'age' => ( is=>'rw', isa=>'Int', default=>40 );
has 'spouse' => ( is=>'rw', isa=>'Person' );
has chi => (is=>'rw', isa=>'ArrayRef[Any]', default=>sub{ [1..3] } );

package main;
use v5.14;
use Mongoose;
Mongoose->db( '_mongoose_testing' );
Person->collection->drop;
my $sp = Person->new( name=>'marge' );
my @b;
for my $i ( 1..100 ) {
    my $p = Person->new( name=>'joe' . $i, spouse=>$sp );
    #Person->collection->insert( $p );
    #$p->save;
    push @b, $p;
}
Person->collection->batch_insert( \@b );
#$p->save;
say join ',', @{ Person->find_one->chi };
