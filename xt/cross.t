use strict;
use warnings;
use Test::More;

use lib 't/lib';
use MongooseT; 
my $db = db;

# text configuration
package Item;
use Mongoose::Class;
with 'Mongoose::Document';
has_one queue => 'Queue';

package Queue;
use Mongoose::Class;
with 'Mongoose::Document';
belongs_to item => 'Item';

package main;
sub dd { use YAML; warn Dump( @_ ) }
my $id;
{
    my $q = Queue->new;
    $q->save;
    my $item = Item->new( queue=>$q );
    $id = $item->save();
}
{
    my $item = Item->find_one();
    warn $item->queue;
    $item->queue->delete;

    $item = Item->find_one();
    warn "Find one:";
    dd( $item->queue );

    my @items = Item->find->all;
    warn "Find all:";
    for(@items) {
        dd( $_->queue );
    }
    ok 1, 'no nada for now';
}

done_testing;
