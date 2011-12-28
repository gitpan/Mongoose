diff --git a/lib/Mongoose.pm b/lib/Mongoose.pm
index f3b82ed..1dc130d 100644
--- a/lib/Mongoose.pm
+++ b/lib/Mongoose.pm
@@ -71,14 +71,14 @@ sub db {
     my %p    = @_ == 1 ? (db_name=>shift) : @_;
     my $now  = delete $p{'-now'};
     $self->_args( \%p );
-    return $self->connect if $now || defined wantarray;
+    return $self->connect if $now || !(defined wantarray);
 }
 
 sub connect {
     my $self = shift;
     my %p    = @_ || %{ $self->_args };
     my $key  = delete( $p{'-class'} ) || 'default';
-    $self->_connection( MongoDB::Connection->new(@_) )
+    $self->_connection( MongoDB::Connection->new(%p) )
       unless ref $self->_connection;
     $self->_db( { $key => $self->_connection->get_database( $p{db_name} ) } );
     return $self->_db->{$key};
