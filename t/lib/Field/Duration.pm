package Field::Duration;

use Moose;
extends 'HTML::FormHandler::Field::Compound';
use DateTime;

our $VERSION = '0.01';

# override validate

sub validate {
    my ( $self ) = @_;

    # get field name
    my $name = $self->name;

    my %duration;

    my $found = 0;
    my @dur_parms;
    my $fieldname;

    my $input = $self->input;
    for my $child ( $self->children )
    {
       next unless exists $input->{$child->accessor};
       $found++;
       my $input = $self->input->{$child->accessor};
       unless ( $input =~ /^\d+$/ )
       {
          $self->add_error( "Invalid value for " . $self->label . " " . $child->label );
          next;
       }
       push @dur_parms, ($child->accessor => $input); 
       $child->value( $input );
    }

    # Check that some subfield has been entered 
    if ( $self->required ) {
        unless ( $found ) {
            $self->add_error( "Duration is required" );
            return;
        }
    }
    # set the value
    my $duration = DateTime::Duration->new(@dur_parms);
    $self->value($duration);

}




=head1 NAME

HTML::FormHandler::Field::Duration - Produces DateTime::Duration from HTML form values 

=cut

1;

