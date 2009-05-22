package HTML::FormHandler::Field::Compound;

use Moose;
use MooseX::AttributeHelpers;
extends 'HTML::FormHandler::Field';
with 'HTML::FormHandler::Fields';

=head1 NAME

HTML::FormHandler::Field::Compound - field consisting of subfields

=head1 SYNOPSIS

This field class is designed as the base (parent) class for fields with
multiple subfields. Examples are L<HTML::FormHandler::DateTime>
and L<HTML::FormHandler::Duration>.

A compound parent class requires the use of sub-fields prepended
with the parent class name plus a dot

   has_field 'birthdate' => ( type => 'DateTime' );
   has_field 'birthdate.year' => ( type => 'Year' );
   has_field 'birthdate.month' => ( type => 'Month' );
   has_field 'birthdate.day' => ( type => 'MonthDay');

If all validation is performed in the parent class so that no
validation is necessary in the child classes, then the field class
'Nested' may be used.

Error messages will be applied to both parent classes and child
classes unless the 'errors_on_parent' flag is set. (This flag is
set for the 'Nested' field class.)

The process method of this field runs the process methods on the child fields
and then builds a hash of these fields values.  This hash is available for 
further processing by L<HTML::FormHandler::Field/actions> and the validate method.

Example:

  has_field 'date_time' => ( 
      type => 'Compound',
      actions => [ { transform => sub{ DateTime->new( $_[0] ) } } ],
  );
  has_field 'date_time.year' => ( type => 'Text', );
  has_field 'date_time.month' => ( type => 'Text', );
  has_field 'date_time.day' => ( type => 'Text', );


=head2 widget

Widget type is 'compound'

=cut

has '+widget' => ( default => 'compound' );

has '+field_name_space' => ( default => sub {
      my $self = shift;
      return $self->form->field_name_space
           if $self->form && $self->form->field_name_space;
      return '';
   },
);
sub BUILD
{
   my $self = shift;
   $self->_build_fields;
}

sub build_node
{
   my $self = shift;

   my $input = $self->input;

   # is there a better way to do this? 
   if( ref $input eq 'HASH' )
   {
      foreach my $field ( $self->fields )
      {
         my $field_name = $field->name;
         # move values to "input" slot
         if ( exists $input->{$field_name} )
         {
            $field->input( $input->{$field_name} )
         }
         elsif ( $field->has_input_without_param )
         {
            $field->input( $field->input_without_param );
         }
      }
   }
   $self->clear_fif;
   return unless $self->has_fields;
   $self->_fields_validate;
   my %value_hash;
   for my $field ( $self->fields )
   { 
      $value_hash{ $field->accessor } = $field->value;
   }
   $self->value( \%value_hash );
} 


__PACKAGE__->meta->make_immutable;
no Moose;
1;
