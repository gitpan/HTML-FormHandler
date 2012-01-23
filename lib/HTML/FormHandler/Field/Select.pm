package HTML::FormHandler::Field::Select;
# ABSTRACT: select fields

use Moose;
extends 'HTML::FormHandler::Field';
use Carp;
our $VERSION = '0.03';


has 'options' => (
    isa       => 'ArrayRef',
    is        => 'rw',
    traits    => ['Array'],
    auto_deref => 1,
    handles  => {
        all_options => 'elements',
        reset_options => 'clear',
        clear_options => 'clear',
        has_options => 'count',
        num_options => 'count',
    },
    lazy    => 1,
    builder => 'build_options'
);

sub build_options { [] }
has 'options_from' => ( isa => 'Str', is => 'rw', default => 'none' );
has 'do_not_reload' => ( isa => 'Bool', is => 'ro' );

sub BUILD {
    my $self = shift;

    if( $self->options && $self->has_options ) {
        $self->options_from('build');
        $self->default_from_options([$self->options]);
    }
    $self->input_without_param; # vivify
}

has 'set_options' => ( isa => 'Str', is => 'ro');
sub _set_options_meth {
    my $self = shift;
    return $self->set_options if $self->set_options;
    my $name = $self->full_name;
    if( $name =~ /\./ ) {
        $name =~ s/\.\d+\./_/g;
        $name =~ s/\./_/g;
    }
    return 'options_' . $name;
}
sub _can_form_options {
    my $self = shift;
    my $set_options = $self->_set_options_meth;
    return
        unless $self->form &&
            $set_options &&
            $self->form->can( $set_options );
    return $set_options;
}

sub _form_options {
    my $self = shift;
    return unless (my $meth = $self->_can_form_options);
    my $attr = $self->form->meta->find_method_by_name( $meth );
    if ( $attr and $attr->isa('Moose::Meta::Method::Accessor') ) {
        return $self->form->$meth;
    }
    else {
        return $self->form->$meth($self);
    }
}

has 'multiple'         => ( isa => 'Bool', is => 'rw', default => '0' );
# following is for unusual case where a multiple select is a has_many type relation
has 'has_many'         => ( isa => 'Str', is => 'rw' );
has '+deflate_to'      => ( default => 'fif' );
has 'size'             => ( isa => 'Int|Undef', is => 'rw' );
has 'label_column'     => ( isa => 'Str',       is => 'rw', default => 'name' );
has 'localize_labels'  => ( isa => 'Bool', is => 'rw' );
has 'active_column'    => ( isa => 'Str',       is => 'rw', default => 'active' );
has 'auto_widget_size' => ( isa => 'Int',       is => 'rw', default => '0' );
has 'sort_column'      => ( isa => 'Str',       is => 'rw' );
has '+widget'          => ( default => 'select' );
has 'empty_select'     => ( isa => 'Str',       is => 'rw' );
has '+input_without_param' => ( lazy => 1, builder => 'build_input_without_param' );
sub build_input_without_param {
    my $self = shift;
    if( $self->multiple ) {
        $self->not_nullable(1);
        return [];
    }
    else {
        return '';
    }
}

our $class_messages = {
    'select_not_multiple' => 'This field does not take multiple values',
    'select_invalid_value' => '\'[_1]\' is not a valid value',
};

sub get_class_messages  {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

sub select_widget {
    my $field = shift;

    my $size = $field->auto_widget_size;
    return $field->widget unless $field->widget eq 'select' && $size;
    my $options = $field->options || [];
    return 'select' if @$options > $size;
    return $field->multiple ? 'checkbox_group' : 'radio_group';
}

sub as_label {
    my $field = shift;

    my $value = $field->value;
    return unless defined $value;

    for ( $field->options ) {
        return $_->{label} if $_->{value} eq $value;
    }
    return;
}

sub _inner_validate_field {
    my ($self) = @_;

    my $value = $self->value;
    return 1 unless defined $value;    # nothing to check

    if ( ref $value eq 'ARRAY' &&
        !( $self->can('multiple') && $self->multiple ) )
    {
        $self->add_error( $self->get_message('select_not_multiple') );
        return;
    }
    elsif ( ref $value ne 'ARRAY' && $self->multiple ) {
        $value = [$value];
        $self->_set_value($value);
    }

    # create a lookup hash
    my %options = map { $_->{value} => 1 } @{ $self->options };
    if( $self->has_many ) {
        $value = [map { $_->{$self->has_many} } @$value];
    }
    for my $value ( ref $value eq 'ARRAY' ? @$value : ($value) ) {
        unless ( $options{$value} ) {
            $self->add_error($self->get_message('select_invalid_value'), $value);
            return;
        }
    }
    return 1;
}

sub _result_from_object {
    my ( $self, $result, $item ) = @_;

    $result = $self->next::method( $result, $item );
    $self->_load_options;
    $result->_set_value($self->default)
        if( defined $self->default && not $result->has_value );
    return $result;
}

sub _result_from_fields {
    my ( $self, $result ) = @_;

    $result = $self->next::method($result);
    $self->_load_options;
    $result->_set_value($self->default)
        if( defined $self->default && not $result->has_value );
    return $result;
}

sub _result_from_input {
    my ( $self, $result, $input, $exists ) = @_;

    $input = ref $input eq 'ARRAY' ? $input : [$input]
        if $self->multiple;
    $result = $self->next::method( $result, $input, $exists );
    $self->_load_options;
    $result->_set_value($self->default)
        if( defined $self->default && not $result->has_value );
    return $result;
}

sub _load_options {
    my $self = shift;

    return
        if ( $self->options_from eq 'build' ||
        ( $self->has_options && $self->do_not_reload ) );
    my @options;
    if ( $self->_can_form_options ) {
        @options = $self->_form_options;
        $self->options_from('method');
    }
    elsif ( $self->form ) {
        my $full_accessor;
        $full_accessor = $self->parent->full_accessor if $self->parent;
        @options = $self->form->lookup_options( $self, $full_accessor );
        $self->options_from('model') if scalar @options;
    }
    return unless @options;    # so if there isn't an options method and no options
                               # from a table, already set options attributes stays put

    # allow returning arrayref
    if ( ref $options[0] eq 'ARRAY' ) {
        @options = @{ $options[0] };
    }
    return unless @options;
    my $opts;
    # if options_<field_name> is returning an already constructed array of hashrefs
    if ( ref $options[0] eq 'HASH' ) {
        $opts = \@options;
        $self->default_from_options($opts);
    }
    else {
        croak "Options array must contain an even number of elements for field " . $self->name
            if @options % 2;
        push @{$opts}, { value => shift @options, label => shift @options } while @options;
    }
    if ($opts) {
        my $opts = $self->sort_options($opts);    # allow sorting options
        $self->options($opts);
    }
}

# This is because setting 'checked => 1' or 'selected => 1' in an options
# hashref is the equivalent of setting a default on the field. Originally
# that was handled only in rendering, but it moved knowledge about where
# the 'fif' value came from into the renderer, which was bad. So instead
# we're setting the defaults from the options.
# It's probably better to use 'defaults' to start with, but since there are
# people using this method, this at least normalizes it.
sub default_from_options {
    my ( $self, $options ) = @_;

    my @defaults = map { $_->{value} } grep { $_->{checked} || $_->{selected} } @$options;
    if( scalar @defaults ) {
        if( $self->multiple ) {
            $self->default(\@defaults);
        }
        else {
            $self->default($defaults[0]);
        }
    }
}

sub sort_options { shift; return shift; }

before 'value' => sub {
    my $self  = shift;

    return undef unless $self->has_result;
    my $value = $self->result->value;

    if( $self->multiple ) {
        if ( !defined $value || $value eq '' ) {
            $self->_set_value( [] );
        }
        elsif ( $self->has_many && scalar @$value && ref($value->[0]) ne 'HASH' ) {
            my @new_values;
            foreach my $ele (@$value) {
                push @new_values, { $self->has_many => $ele };
            }
            $self->_set_value( \@new_values );
        }
    }
};

sub deflate {
    my ( $self, $value ) = @_;

    return $value unless ( $self->has_many && $self->multiple );

    # the following is for the edge case of a has_many select
    return $value unless ref($value) eq 'ARRAY' && scalar @$value && ref($value->[0]) eq 'HASH';
    return [map { $_->{$self->has_many} } @$value];
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Field::Select - select fields

=head1 VERSION

version 0.36000

=head1 DESCRIPTION

This is a field that includes a list of possible valid options.
This can be used for select and multiple-select fields.
Widget type is 'select'.

Because select lists and checkbox_groups do not return an HTTP
parameter when the entire list is unselected, the Select field
must assume that the lack of a param means unselection. So to
avoid setting a Select field, it must be set to inactive, not
merely not included in the HTML for a form.

This field type can also be used for fields that use the
'radio_group' widget, and the 'checkbox_group' widget (for
selects with multiple flag turned on, or that use the Multiple
field).

The 'options' array can come from four different places.
The options attribute itself, either declaratively or using a
'build_options' method in the field, from a method in the
form ('options_<fieldname>') or from the database.

In a field declaration:

   has_field 'opt_in' => ( type => 'Select', widget => 'radio_group',
      options => [{ value => 0, label => 'No'}, { value => 1, label => 'Yes'} ] );

In a custom field class:

   package MyApp::Field::WeekDay;
   use Moose;
   extends 'HTML::FormHandler::Field::Select';
   ....
   sub build_options {
       my $i = 0;
       my @days = ('Sunday', 'Monday', 'Tuesday', 'Wednesday',
           'Thursday', 'Friday', 'Saturday' );
       return [
           map {
               {   value => $i++, label => $_ }
           } @days
       ];
   }

In a form:

   has_field 'fruit' => ( type => 'Select' );
   sub options_fruit {
       return (
           1   => 'apples',
           2   => 'oranges',
           3   => 'kiwi',
       );
   }
   -- or --
   has 'options_fruit' => ( is => 'rw', traits => ['Array'],
       default => sub { [1 => 'apples', 2 => 'oranges',
           3 => 'kiwi'] } );

Notice that, as a convenience, you can return a simple array (or arrayref)
for the options array in the 'options_field_name' method. The hashrefs with
'value' and 'label' keys will be constructed for you by FormHandler. The
arrayref of hashrefs format can be useful if you want to add another key
to the hashes that you can use in creating the HTML:

   sub options_license
   {
      my $self = shift;
      return unless $self->schema;
      my $licenses = $self->schema->resultset('License')->search({active => 1},
           {order_by => 'sequence'});
      my @selections;
      while ( my $license = $licenses->next ) {
         push @selections, { value => $license->id, label => $license->label,
              note => $license->note };
      }
      return @selections;
   }

To have an option being shown, but disabled (thus not selectable), use the
'disabled' key with a true value inside this hashref. Let's extend the example
above, adding also inactive licenses, and disabling them.  Keep in mind that a
disabled option can be made selectable later, by removing the disabled
attribute, e.g. using javascript.

   sub options_license
   {
      my $self = shift;
      return unless $self->schema;
      my $licenses = $self->schema->resultset('License')->search(undef,
           {order_by => 'sequence'});
      my @selections;
      while ( my $license = $licenses->next ) {
         push @selections, { value => $license->id, label => $license->label,
              note => $license->note, disabled => ($license->active == 0) ? 1 : 0 };
      }
      return @selections;
   }

The final source of the options array is a database when the name of the
accessor is a relation to the table holding the information used to construct
the select list.  The primary key is used as the value. The other columns used are:

    label_column  --  Used for the labels in the options (default 'name')
    active_column --  The name of the column to be used in the query (default 'active')
                      that allows the rows retrieved to be restricted
    sort_column   --  The name of the column used to sort the options

See also L<HTML::FormHandler::Model::DBIC>, the 'lookup_options' method.

If the options come from the options_<fieldname> method or the database, they
will be reloaded every time the form is reloaded because the available options
may have changed. To prevent this from happening when the available options are
known to be static, set the 'do_not_reload' flag, and the options will not be
reloaded after the first time

The sorting of the options may be changed using a 'sort_options' method in a
custom field class. The 'Multiple' field uses this method to put the already
selected options at the top of the list.

=head1 Attributes and Methods

=head2 options

This is an array of hashes for this field.
Each has must have a label and value keys.

=head2 set_options

Name of form method that sets options

=head2 multiple

If true allows multiple input values

=head2 size

This can be used to store how many items should be offered in the UI
at a given time.  Defaults to 0.

=head2 empty_select

Set to the string value of the select label if you want the renderer
to create an empty select value. This only affects rendering - it does
not add an entry to the list of options.

   has_field 'fruit' => ( type => 'Select,
        empty_select => '---Choose a Fruit---' );

=head2 label_column

Sets or returns the name of the method to call on the foreign class
to fetch the text to use for the select list.

Refers to the method (or column) name to use in a related
object class for the label for select lists.

Defaults to "name"

=head2 localize_labels

For the renderers: whether or not to call the localize method on the select
labels. Default is off.

=head2 active_column

Sets or returns the name of a boolean column that is used as a flag to indicate that
a row is active or not.  Rows that are not active are ignored.

The default is "active".

If this column exists on the class then the list of options will included only
rows that are marked "active".

The exception is any columns that are marked inactive, but are also part of the
input data will be included with brackets around the label.  This allows
updating records that might have data that is now considered inactive.

=head2 auto_widget_size

This is a way to provide a hint as to when to automatically
select the widget to display for fields with a small number of options.
For example, this can be used to decided to display a radio select for
select lists smaller than the size specified.

See L<select_widget> below.

=head2 sort_column

Sets or returns the column used in the foreign class for sorting the
options labels.  Default is undefined.

If this column exists in the foreign table then labels returned will be sorted
by this column.

If not defined or the column is not found as a method on the foreign class then
the label_column is used as the sort condition.

=head2 select_widget

If the widget is 'select' for the field then will look if the field
also has a L<auto_widget_size>.  If the options list is less than or equal
to the L<auto_widget_size> then will return C<radio_group> if L<multiple> is false,
otherwise will return C<checkbox_group>.

=head2 as_label

Returns the option label for the option value that matches the field's current value.
Can be helpful for displaying information about the field in a more friendly format.
This does a string compare.

=head2 error messages

Customize 'select_invalid_value' and 'select_not_multiple'. Though neither of these
messages should really be seen by users in a properly constructed select.

=head1 Database relations

Also see L<HTML::FormHandler::TraitFor::Model::DBIC>.

The single select is for a DBIC 'belongs_to' relation. The multiple select is for
a 'many_to_many' relation.

There is very limited ability to do multiple select with 'has_many' relations.
It will only work in very specific circumstances, and requires setting
the 'has_many' attribute to the name of the primary key of the related table.
This is a somewhat peculiar data structure for a relational database, and may
not be what you really want. A 'has_many' is usually represented with a Repeatable
field, and may require custom code if the form structure doesn't match the database
structure. See L<HTML::FormHandler::Manual::Cookbook>.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

