use Test::More tests => 16;

use lib 't/lib';

use_ok( 'HTML::FormHandler::Field::Duration');

my $field = HTML::FormHandler::Field::Duration->new( name => 'duration' );

ok( $field, 'get compound field');

my $input = {
      hours => 1,
      minutes => 2,
};

$field->input($input);

is_deeply( $field->input, $input, 'field input is correct');

is_deeply( $field->fif, $input, 'field fif is same');

{
   package Duration::Form;
   use HTML::FormHandler::Moose;
   extends 'HTML::FormHandler';

   has_field 'name' => ( type => 'Text' );
   has_field 'duration' => ( type => 'Duration' );
   has_field 'duration.hours' => ( type => 'Nested' );
   has_field 'duration.minutes' => ( type => 'Nested' );

}

my $form = Duration::Form->new;
ok( $form, 'get compound form' );
ok( $form->field('duration'), 'duration field' );
ok( $form->field('duration.hours'), 'duration.hours field' );

my $params = { name => 'Testing', 'duration.hours' => 2, 'duration.minutes' => 30 };

$form->process( params => $params );
ok( $form->validated, 'form validated' );

is_deeply($form->fif, $params, 'get fif with right value');
is( $form->field('duration')->value->hours, 2, 'duration value is correct');

{
   package Form::Start;
   use HTML::FormHandler::Moose;
   extends 'HTML::FormHandler';

   has_field 'name' => ( type => 'Text' );
   has_field 'start_date' => ( type => 'DateTime' );
   has_field 'start_date.month' => ( type => 'Month' );
   has_field 'start_date.day' => ( type => 'MonthDay' );
   has_field 'start_date.year' => ( type => 'Year' );

}

my $dtform = Form::Start->new;
ok( $dtform, 'datetime form' );
$params = { name => 'DT_testing', 'start_date.month' => '10',
    'start_date.day' => '2', 'start_date.year' => '2008' };
$dtform->process( params => $params );

ok( $dtform->validated, 'form validated' );

is( $dtform->field('start_date')->value->mdy, '10-02-2008', 'datetime value');

{
   package Field::MyCompound;
   use HTML::FormHandler::Moose;
   extends 'HTML::FormHandler::Field::Compound';

   has_field 'aaa' => ( type => 'Text' );
   has_field 'bbb' => ( type => 'Text' );
}


{
   package Form::TestValues;
   use HTML::FormHandler::Moose;
   extends 'HTML::FormHandler';

   has_field 'compound' => ( type => '+Field::MyCompound' );
}
$form = Form::TestValues->new;
ok( $form, 'Compound form with separate fields declarations created' );

$params = { 
    'compound.aaa' => 'aaa',
    'compound.bbb' => 'bbb',
};
$form->process( params => $params );
is_deeply( $form->values, { compound => { aaa => 'aaa', bbb => 'bbb' } }, 'Compound with separate fields - values in hash' );
is_deeply( $form->fif, $params, 'get fif from compound field' );



