use strict;
use warnings;
use Test::More;
my $tests = 3;
plan tests => $tests;

use_ok('HTML::FormHandler');

{

   package My::Form;
   use HTML::FormHandler::Moose;
   extends 'HTML::FormHandler';

   has '+name'         => ( default  => 'testform_' );
   has_field 'optname' => ( temp     => 'First' );
   has_field 'reqname' => ( required => 1 );
   has_field 'somename';
   has_field 'my_selected' => ( type => 'Checkbox' );
   has_field 'must_select' => ( type => 'Checkbox', required => 1 );

   sub field_list
   {
      return [
         fruit   => 'Select',
         optname => { temp => 'Second' }
      ];
   }

   sub options_fruit
   {
      return (
         1 => 'apples',
         2 => 'oranges',
         3 => 'kiwi',
      );
   }
}

my $form = My::Form->new;
ok( $form, 'form created');

my $field = 'test';
ok( !$field->isa('HTML::FormHandler::Field'), 'not a field obj' );

