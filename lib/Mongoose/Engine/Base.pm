package Mongoose::Engine::Base;
$Mongoose::Engine::Base::VERSION = '0.27';
use Moose::Role;
use Params::Coerce;
use Scalar::Util qw/refaddr reftype/;
use Carp;
use List::Util qw/first/;
use Mongoose::Cursor; #initializes moose

with 'Mongoose::Role::Collapser';
with 'Mongoose::Role::Expander';
with 'Mongoose::Role::Engine';

sub collapse {
    my ( $self, @scope )=@_;

    # circularity ?
    if( my $duplicate = first { refaddr($self) == refaddr($_) } @scope ) { 
        #say "----CIRC=$duplicate";
        my $class = blessed $duplicate;
        my $ref_id = $duplicate->_id;
        return undef unless defined $class && $ref_id;
        return undef if $self->_id && $self->_id eq $ref_id; # prevent self references?
        return { '$ref' => $class->meta->{mongoose_config}->{collection_name}, '$id'=>$ref_id };
    }
    my $packed = { %$self }; # cheesely clone the data
    for my $key ( keys %$packed ) {
        my $attrib = $self->meta->get_attribute($key);

        # treat special cases based on Moose attribute defs or traits
        if( defined $attrib ) {
            delete $packed->{$key} , next
                if $attrib->does('Mongoose::Meta::Attribute::Trait::DoNotMongoSerialize');

            next if $attrib->does('Mongoose::Meta::Attribute::Trait::Raw');

            if( my $type = $attrib->type_constraint ) {
                if( $type->is_a_type_of('FileHandle') ) {
                    my $grid = $self->db->get_gridfs;
                    my $id = $grid->put( delete $packed->{$key} );
                    $packed->{$key} = { '$ref'=>'FileHandle', '$id'=>$id };
                }
            }
        }
        $packed->{$key} = $self->_collapse( $packed->{$key}, @scope );
    }
    return $packed;
}

sub _collapse {
    my ($self, $value, @scope ) = @_;
    if( my $class = blessed $value ) {
        #say "checking.... $class.... $self: " . $self->_id;
        if( ref $value eq 'HASH' && defined ( my $ref_id = $value->{_id} ) ) {
            # it has an id, so join ref it
            return { '$ref' => $class->meta->{mongoose_config}->{collection_name}, '$id'=>$ref_id };
        } else {
            return $self->_unbless( $value, $class, @scope );
        }
    }
    elsif( ref $value eq 'ARRAY' ) {
        my @docs;
        my $aryclass;
        for my $item ( @$value ) {
            $aryclass ||= blessed( $item );
            if( $aryclass && $aryclass->does('Mongoose::EmbeddedDocument') ) {
                push @docs, $item->collapse(@scope, $self);
            } elsif( $aryclass && $aryclass->does('Mongoose::Document') ) {
                $item->_save( @scope, $self );
                my $id = $item->_id;
                push @docs, { '$ref' => $aryclass->meta->{mongoose_config}->{collection_name}, '$id'=>$id };
            } else {
                push @docs, $item;
            }
        }
        return \@docs;
    }
    elsif( ref $value eq 'HASH' ) {
        my $ret = {};
        my @docs;
        for my $key ( keys %$value ) {
            if( blessed $value->{$key} ) {
                $ret->{$key} = $self->_unbless( $value->{$key}, blessed($value->{$key}), @scope );;
            } elsif( ref $value->{$key} eq 'ARRAY' ) {
                $ret->{$key} = [ map {
                    $self->_collapse( $_, @scope ) 
                  } @{ $value->{$key} } ];
            } else {
                $ret->{$key} = $value->{$key};
            }
        }
        return $ret;
    } else {
        return $value;
    }
}

sub _unbless {
    my ($self, $obj, $class, @scope ) = @_;
    my $ret = $obj;
    if( $class->can('meta') ) { # only mooses from here on
        if( $class->does('Mongoose::EmbeddedDocument') ) {
            $ret = $obj->collapse( @scope, $self ) or next;
        }
        elsif( $class->does('Mongoose::Document') ) {
            #say 'saving...: ', join',',$self,$obj,$class,'.',@scope;

            $obj->_save( @scope, $self );
            my $id = $obj->_id;

            $ret = { '$ref' => $class->meta->{mongoose_config}->{collection_name}, '$id'=>$id };
        }
        elsif( $class->isa('Mongoose::Join') ) {
            my @objs = $obj->_save( $self, @scope );
            $ret = \@objs;
        }
    } elsif( ref $obj eq 'DateTime' ) {
        # DateTime as raw always
        $ret = $obj;
    } else {
        # non-moose class
        my $reftype = reftype($obj);
        if( $reftype eq 'ARRAY' ) {
            $ret = [ @$obj ];
        } elsif( $reftype eq 'SCALAR' ) {
            $ret = $$obj;
        } elsif( $reftype eq 'HASH' ) {
            $ret = { %{$obj} };
        }
    }
    return $ret;
}

sub expand {
    my ($self,$doc,$fields,$scope)=@_;
    my @later;
    my $config = $self->meta->{mongoose_config};
    my $coll_name = $config->{collection_name};
    my $class_main = ref $self || $self;

    $scope = {} unless ref $scope eq 'HASH';

    # check if it's an straight ref
    if( defined $doc->{'$id'} ) {
        my $ref_id = $doc->{'$id'};
        defined $scope->{$ref_id} and return $scope->{$ref_id};
        return $class_main->find_one({ _id=>$doc->{'$id'} });
    }

    for my $attr ( $class_main->meta->get_all_attributes ) {
        my $name = $attr->name;
        next unless exists $doc->{$name};
        my $type = $attr->type_constraint or next;
        my $class = $self->_get_blessed_type( $type );
        $class or next;

        if( defined $attr && $attr->does('Mongoose::Meta::Attribute::Trait::Raw') ) {
            next;
        }
        elsif( $type->is_a_type_of('HashRef') ) {
            if( defined $type->{type_parameter} ) {
                # HashRef[ parameter ]
                my $param = $type->{type_parameter};
                if( my $param_class = $param->{class} ) {
                    for my $key ( keys %{ $doc->{$name} || {} } ) {
                        $doc->{$name}->{$key} = $param_class->expand( $doc->{$name}->{$key}, undef, $scope );
                    }
                    next;
                } else {
                    next;
                }
            } else {
                # nothing to do on pure HASH
                next;
            }
        }
        elsif( $type->is_a_type_of('ArrayRef') ) {
            if( defined $type->{type_parameter} ) {
                # ArrayRef[ parameter ]
                my @objs;
                my $param = $type->{type_parameter};
                if( my $param_class = $param->{class} ) {
                    for my $item ( @{ $doc->{$name} || [] } ) {
                        if ( $param_class->does('Mongoose::EmbeddedDocument') ) {
                            push @objs, $param_class->expand($item);
                        }
                        elsif ( $param_class->does('Mongoose::Document') ) {
                            my $_id = delete $item->{'$id'};
                            if( my $circ_doc = $scope->{ $_id } ) {
                                push @objs, bless( $circ_doc , $param_class );
                            } else {
                                #$scope->{ $_id } = $doc->{
                                my $ary_obj = $param_class->find_one({ _id=>$_id }, undef, $scope );
                                push @objs, $ary_obj if defined $ary_obj;
                            }
                        }
                    }
                } else {
                    @objs = @{ $doc->{$name} || [] };
                }
                $doc->{$name} = \@objs;
                next;
            } else {
                # ARRAY
                next;
            }
        }
        elsif( $type->is_a_type_of('FileHandle') ) {
            my $file = $self->db->get_gridfs->find_one({ _id=>$doc->{$name}->{'$id'} });
            delete $doc->{$name}, next unless defined $file;
            $doc->{$name} = bless $file, 'Mongoose::File';
            next;
        }

        if( $class->can('meta') ) { # moose subobject

            if( $class->does('Mongoose::EmbeddedDocument') ) {
                $doc->{$name} = bless $doc->{$name}, $class;
            }
            elsif( $class->does('Mongoose::Document') ) {
                if( my $_id = delete $doc->{$name}->{'$id'} ) {
                    if( my $circ_doc = $scope->{"$_id"} ) {
                        $doc->{$name} = bless( $circ_doc , $class );
                        $scope->{ "$circ_doc->{_id}" } = $doc->{$name};
                    } else {
                        $scope->{ "$doc->{_id}" } = $doc;
                        $doc->{$name} = $class->find_one({ _id=>$_id }, undef, $scope );
                    }
                }
            }
            elsif( $class->isa('Mongoose::Join') ) {
                my $ref_arr = delete( $doc->{$name} );
                my $ref_class = $type->type_parameter->class ;
                $doc->{$name} = bless {
                    class=>$class_main, field=>$name, parent=>$doc->{_id},
                    with_class=>$ref_class, children=>$ref_arr, buffer=>{} } => $class;
            }
        }
        else { #non-moose
            my $data = delete $doc->{$name};
            my $data_type =  ref $data;

            if( !$data_type ) {
                push @later, { attrib=>$name, value=>$data };
            } else {
                $doc->{$name} = bless $data => $class;
            }
        }
    }

    return undef unless defined $doc;
    my $obj = bless $doc => $class_main;
    for( @later )  {
        my $attr = $class_main->meta->get_attribute($_->{attrib});
        if( defined $attr ) {
            # works for read-only values
            $attr->set_value($obj, $_->{value});
        } else {
            # sometimes get_attribute is undef, old method instead:
            my $meth = $_->{attrib};
            $obj->$meth($_->{value});
        }
    }
    return $obj;
}

sub _joint_fields {
    my $self = shift;
    return map { $_->name }
        grep {
            $_->type_constraint->isa('Mongoose::Join')
        }
        $self->meta->get_all_attributes ;
}

sub fix_integrity {
    my ($self, @fields ) = @_;
    my $id = $self->_id;
    @fields = $self->_joint_fields
        unless scalar @fields;
    for my $field ( @fields ) {
        my @children = $self->$field->_children_refs;
        $self->collection->update( { _id=>$id }, { '$set'=>{ $field=>\@children } } );
    }
}

sub _unbless_full {
    require Data::Structure::Util;
    Data::Structure::Util::unbless( shift );
}

sub save {
    &_save(@_);
}

sub _save {
    my ($self, @scope )=@_;
    my $coll = $self->collection;
    my $doc = $self->collapse( @scope );
    return unless defined $doc;

    if( $self->_id  ) {
        ## update on my id
        my $id = $self->_id;
        my $ret = $coll->update( { _id=>$id }, $doc, { upsert=>1 } );
        return $id;
    } else {
        if( ref $self->meta->{mongoose_config}->{pk} ) {
            # if we have a pk and no _id, we must have a new
            # document, so we insert to allow the pk constraint
            # to ensure uniqueness; the 'safe' parameter ensures
            # an exception is thrown on a duplicate
            my $id = $coll->insert( $doc, { safe => 1 } );
            $self->_id( $id );
            return $id;
        } else {
            # save without pk
            my $id = $coll->save( $doc );
            $self->_id( $id );

            # if there are any new, unsaved, documents in the scope,
            # we have circular relation between $self and @scope
            my @unsaved;
            for my $x (@scope) {
                unless($x->_id) {
                    push @unsaved, $x;
                }
            }

            if (@unsaved) {
                while (my $x = pop(@unsaved)) {
                    $x->_save(@unsaved);
                }
                $self->_save;
            }

            return $id;
        }
    }
}

sub _get_blessed_type {
    my ($self,$type) = @_;
    my $class = $type->name or return;
    my $parent = $type->parent;
    return $class unless defined $parent;
    return $class if $parent eq 'Object';
    return $parent->name;
}

# shallow delete
sub delete {
    my ($self, $args )=@_;
    return $self->collection->remove($args) if ref $args;
    my $id = $self->_id;
    return $self->collection->remove({ _id => $id }) if ref $id;
    my $pk = $self->_primary_key_from_hash();
    return $self->collection->remove($pk) if ref $pk;
    return undef;
}

#sub delete_cascade {
#   my ($self, $args )=@_;
#   #TODO delete related collections
#}

sub db {
    my $self=shift;
    return Mongoose->_db_for_class( ref $self || $self )
        or croak 'MongoDB not set. Set Mongoose->db("name") first';
}

sub collection {
    my ($self, $new_collection) = @_;
    my $db = $self->db;

    # getter
    my $config = $self->meta->{mongoose_config};
    $new_collection or return $config->{collection}
        || ( $config->{collection} = $db->get_collection( $config->{collection_name} ) );

    # setter
    my $is_singleton = ! ref $self;
    if( ref($new_collection) eq 'MongoDB::Collection' ) {
        # changing collection objects directly
        if( $is_singleton ) {
            $config->{collection_name} = $new_collection->name;
            return $config->{collection} = $new_collection;
        } else {
            my $class = ref $self;
            Carp::confess "Changing the object collection is not currently supported. Use $class->collection() instead";
        }
    }
    elsif( $new_collection ) {
        # setup a new collection by name
        if( $is_singleton ) {
            $config->{collection_name} = $new_collection;
            return $config->{collection} = $db->get_collection( $new_collection );
        } else {
            my $class = ref $self;
            Carp::confess "Changing the object collection is not currently supported. Use $class->collection() instead";
        }
    }
}

sub _primary_key_from_hash {
    my ($self,$hash)=@_;
    my @keys = @{ $self->meta->{mongoose_config}->{pk} || [] };
    return { map { $_ => $self->{$_} } @keys };
}

sub _collection_name {
    my $self = shift;
    return $self->meta->{mongoose_config}->{collection_name} ;
}

sub find {
    my ($self,$query,$attrs) = @_;
    my $cursor = bless $self->collection->find($query,$attrs), 'Mongoose::Cursor';
    $cursor->_collection_name( $self->meta->{mongoose_config}->{collection_name} );
    $cursor->_class( ref $self || $self );
    return $cursor;
}

sub query {
    my ($self,$query,$attrs) = @_;
    my $cursor = bless $self->collection->query($query,$attrs), 'Mongoose::Cursor';
    $cursor->_collection_name( $self->meta->{mongoose_config}->{collection_name} );
    $cursor->_class( ref $self || $self );
    return $cursor;
}

sub find_one {
    my $self = shift;
    my $doc;
    if( @_ == 1 && ! ref $_[0] ) {
        $doc = $self->collection->find_one({ _id=>MongoDB::OID->new( value=>$_[0] ) });
        return undef unless defined $doc;
        return $self->expand( $doc );
    } 
    else {
        my ($query,$fields, $scope) = @_;
        $doc = $self->collection->find_one( $query, $fields );
        return undef unless defined $doc;
        return $self->expand( $doc, $fields, $scope );
    }
}

=head1 NAME

Mongoose::Engine::Base - heavy lifting done here

=head1 VERSION

version 0.27

=head1 DESCRIPTION

The Mongoose standard engine. Does all the dirty work. Very monolithic.
Replace it with your engine if you want.

=head1 METHODS

=head2 find_one

Just like L<MongoDB::Collection/find_one>, but blesses the hash document
into your class package.

Also has a handy mode which allows
retrieving an C<_id> directly from an string:

   my $author = Author->find_one( '4dd77f4ebf4342d711000000' ); 

Which expands onto:

   my $author = Author->find_one({
       _id=>MongoDB::OID->new( value=>'4dd77f4ebf4342d711000000' )
   }); 

=head2 find

Just like L<MongoDB::Collection/find>, but returns
a L<Mongoose::Cursor> of documents blessed into
your package.

=head2 query

Just like L<MongoDB::Collection/query>, but returns
a L<Mongoose::Cursor> of documents blessed into
your package.

=head2 delete

Deletes the document in the database.

=head2 collapse

Turns an object into a hash document.

=head2 expand

Turns a hash document back into an object.

=head2 collection

Returns the L<MongoDB::Collection> object for this class or object.

=head2 save

Commits the object to the database.

=head2 db

Returns the object's corresponding L<MongoDB::Database> instance.

=head2 fix_integrity

Checks all L<Mongoose::Join> fields for invalid references to
foreign object ids.

=cut

1;
