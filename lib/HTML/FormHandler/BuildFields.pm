package HTML::FormHandler::BuildFields;

use Moose::Role;

=head1 NAME

HTML::FormHandler::BuildFields - role to build field array

=head1 SYNOPSIS

These are the methods that are necessary to build the fields arrays 
in a form. This is a role which is composed into L<HTML::FormHandler>.

Internal code only. This role has no user interfaces.

=cut

has 'fields_from_model' => ( isa => 'Bool', is => 'rw' );

has 'field_list' => ( isa => 'HashRef|ArrayRef', is => 'rw', default => sub { {} } );

sub has_field_list {
    my ( $self, $field_list ) = @_;
    $field_list ||= $self->field_list;
    if ( ref $field_list eq 'HASH' ) {
        return $field_list if ( scalar keys %{$field_list} );
    }
    elsif ( ref $field_list eq 'ARRAY' ) {
        return $field_list if ( scalar @{$field_list} );
    }
    return;
}

# calls routines to process various field lists
# orders the fields after processing in order to skip
# fields which have had the 'order' attribute set
sub _build_fields {
    my $self = shift;

    my $meta_flist = $self->_build_meta_field_list;
    $self->_process_field_array( $meta_flist, 0 ) if $meta_flist;
    my $flist = $self->has_field_list;
    $self->_process_field_list($flist) if $flist;
    return unless $self->has_fields;

    # order the fields
    # There's a hole in this... if child fields are defined at
    # a level above the containing parent, then they won't
    # exist when this routine is called and won't be ordered.
    # This probably needs to be moved out of here into
    # a separate recursive step that's called after build_fields.

    # get highest order number
    my $order = 0;
    foreach my $field ( $self->all_fields ) {
        $order++ if $field->order > $order;
    }
    $order++;
    # number all unordered fields
    foreach my $field ( $self->all_fields ) {
        $field->order($order) unless $field->order;
        $order++;
    }
}

# process all the stupidly many different formats for field_list
# remove undocumented syntaxes after a while
sub _process_field_list {
    my ( $self, $flist ) = @_;

    if ( ref $flist eq 'ARRAY' ) {
        my @flist_copy = @{$flist};
        $self->_process_field_array( $self->_array_fields( \@flist_copy ) );
        return;
    }
    my %flist_copy = %{$flist};
    $flist = \%flist_copy;
    # these should go away. not really necessary
    if ( $flist->{'required'} || $flist->{'optional'} ) {
        warn
            "the required => {} and optional => {}  field_list syntax is deprecated. please remove.";
        $self->_process_field_array( $self->_hashref_fields( $flist->{'required'}, 1 ) )
            if $flist->{'required'};
        $self->_process_field_array( $self->_hashref_fields( $flist->{'optional'}, 0 ) )
            if $flist->{'optional'};
    }
    # don't encourage use of these two. functionality too limited.
    $self->_process_field_array( $self->model_fields ) if $self->fields_from_model;
    $self->_process_field_array( $self->_auto_fields( $flist->{'auto_required'}, 1 ) )
        if $flist->{'auto_required'};
    $self->_process_field_array( $self->_auto_fields( $flist->{'auto_optional'}, 0 ) )
        if $flist->{'auto_optional'};
}

# loops through all inherited classes and composed roles
# to find fields specified with 'has_field'
sub _build_meta_field_list {
    my $self = shift;
    my @field_list;

    foreach my $sc ( reverse $self->meta->linearized_isa ) {
        my $meta = $sc->meta;
        if ( $meta->can('calculate_all_roles') ) {
            foreach my $role ( reverse $meta->calculate_all_roles ) {
                if ( $role->can('field_list') && $role->has_field_list ) {
                    foreach my $fld_def ( @{ $role->field_list } ) {
                        my %new_fld = %{$fld_def};    # copy hashref
                        push @field_list, \%new_fld;
                    }
                }
            }
        }
        if ( $meta->can('field_list') && $meta->has_field_list ) {
            foreach my $fld_def ( @{ $meta->field_list } ) {
                my %new_fld = %{$fld_def};            # copy hashref
                push @field_list, \%new_fld;
            }
        }
    }
    return \@field_list if scalar @field_list;
}

# munges the field_list auto fields into an array of field attributes
sub _auto_fields {
    my ( $self, $fields, $required ) = @_;

    my @new_fields;
    foreach my $name (@$fields) {
        push @new_fields,
            {
            name     => $name,
            type     => $self->guess_field_type($name),
            required => $required
            };
    }
    return \@new_fields;
}

# munges the field_list hashref fields into an array of field attributes
sub _hashref_fields {
    my ( $self, $fields, $required ) = @_;
    my @new_fields;
    while ( my ( $key, $value ) = each %{$fields} ) {
        unless ( ref $value eq 'HASH' ) {
            $value = { type => $value };
        }
        if ( defined $required ) {
            $value->{required} = $required;
        }
        push @new_fields, { name => $key, %$value };
    }
    return \@new_fields;
}

# munges the field_list array into an array of field attributes
sub _array_fields {
    my ( $self, $fields ) = @_;

    my @new_fields;
    while (@$fields) {
        my $name = shift @$fields;
        my $attr = shift @$fields;
        unless ( ref $attr eq 'HASH' ) {
            $attr = { type => $attr };
        }
        push @new_fields, { name => $name, %$attr };
    }
    return \@new_fields;
}

# loop through array of field hashrefs
sub _process_field_array {
    my ( $self, $fields ) = @_;

    # the point here is to process fields in the order parents
    # before children, so we process all fields with no dots
    # first, then one dot, then two dots...
    my $num_fields   = scalar @$fields;
    my $num_dots     = 0;
    my $count_fields = 0;
    while ( $count_fields < $num_fields ) {
        foreach my $field (@$fields) {
            my $count = ( $field->{name} =~ tr/\.// );
            next unless $count == $num_dots;
            $self->_make_field($field);
            $count_fields++;
        }
        $num_dots++;
    }

}

# Maps the field type to a field class, finds the parent,
# sets the 'form' attribute, calls update_or_create
# The 'field_attr' hashref must have a 'name' key
sub _make_field {
    my ( $self, $field_attr ) = @_;

    $field_attr->{type} ||= 'Text';
    my $type = $field_attr->{type};
    my $name = $field_attr->{name};
    return unless $name;

    my $do_update;
    if ( $name =~ /^\+(.*)/ ) {
        $field_attr->{name} = $name = $1;
        $do_update = 1;
    }

    my $class =
        $type =~ s/^\+// ?
        $self->field_name_space ?
        $self->field_name_space . "::" . $type :
            $type :
        'HTML::FormHandler::Field::' . $type;

    Class::MOP::load_class($class) or
        die "Could not load field class '$type' $class for field '$name'";

    $field_attr->{form} = $self->form if $self->form;
    # parent and name correction for names with dots
    if ( $field_attr->{name} =~ /\./ ) {
        my @names       = split /\./, $field_attr->{name};
        my $simple_name = pop @names;
        my $parent_name = join '.', @names;
        my $parent      = $self->field($parent_name);
        if ($parent) {
            die "The parent of field " . $field_attr->{name} . " is not a Compound Field"
                unless $parent->isa('HTML::FormHandler::Field::Compound');
            $field_attr->{parent} = $parent;
            $field_attr->{name}   = $simple_name;
        }
    }
    elsif ( !( $self->form && $self == $self->form ) ) {
        # set parent
        $field_attr->{parent} = $self;
    }
    $self->_update_or_create( $field_attr->{parent} || $self->form,
        $field_attr, $class, $do_update );
}

# update, replace, or create field
sub _update_or_create {
    my ( $self, $parent, $field_attr, $class, $do_update ) = @_;

    my $index = $parent->field_index( $field_attr->{name} );
    my $field;
    if ( defined $index ) {
        if ($do_update)    # this field started with '+'. Update.
        {
            $field = $parent->field( $field_attr->{name} );
            die "Field to update for " . $field_attr->{name} . " not found"
                unless $field;
            delete $field_attr->{name};
            foreach my $key ( keys %{$field_attr} ) {
                $field->$key( $field_attr->{$key} )
                    if $field->can($key);
            }
        }
        else               # replace existing field
        {
            $field = $class->new( %{$field_attr} );
            $parent->set_field_at( $index, $field );
        }
    }
    else                   # new field
    {
        $field = $class->new( %{$field_attr} );
        $parent->add_field($field);
    }
    $field->form->reload_after_update(1)
        if ( $field->form && $field->reload_after_update );
}

=head1 AUTHORS

HTML::FormHandler Contributors; see HTML::FormHandler

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

use namespace::autoclean;
1;
