use v5.14;
use MongoDB;
use Benchmark qw(cmpthese);

        require version;
cmpthese( 1000000, {
    ver => sub {
        my $b = version::qv( $MongoDB::VERSION ) >= v0.503.3;
    },
    INC => sub {
        my $b =  $INC{'MongoDB/MongoClient.pm'};
    }
});
