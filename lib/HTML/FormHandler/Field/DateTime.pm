package HTML::FormHandler::Field::DateTime;
# ABSTRACT: compound DateTime field

use Moose;
extends 'HTML::FormHandler::Field::Compound';

use DateTime;
use Try::Tiny;
our $VERSION = '0.04';


has '+widget' => ( default => 'Compound' );
has '+inflate_default_method' => ( default => sub { \&datetime_inflate } );

our $class_messages = {
    'datetime_invalid' => 'Not a valid DateTime',
};
sub get_class_messages {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

sub datetime_inflate {
    my ( $self, $value ) = @_;
    return $value unless ref $value eq 'DateTime';
    my %hash;
    foreach my $field ( $self->all_fields ) {
        my $meth = $field->name;
        $hash{$meth} = $value->$meth;
    }
    return \%hash;
}

sub validate {
    my ($self) = @_;
    my @dt_parms;
    foreach my $child ( $self->all_fields ) {
        next unless $child->value;
        push @dt_parms, ( $child->accessor => $child->value );
    }

    # set the value
    my $dt;
    try {
        $dt = DateTime->new(@dt_parms);
    }
    catch {
        $self->add_error( $self->get_message('datetime_invalid') );
    };
    if( $dt ) {
        $self->_set_value($dt);
    }
    else {
        $self->_set_value( {@dt_parms} );
    }
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::DateTime - compound DateTime field

=head1 VERSION

version 0.40057

=head1 DESCRIPTION

This is a compound field that requires you to define the subfields
for month/day/year/hour/minute. Widget type is 'compound'.

If you want to use drop-down select boxes for your DateTime, you
can select fields like:

    has_field 'my_date' => ( type => 'DateTime' );
    has_field 'my_date.month' => ( type => 'Month' );
    has_field 'my_date.day' => ( type => 'MonthDay' );
    has_field 'my_date.year' => ( type => 'Year' );
    has_field 'my_date.hour' => ( type => 'Hour' );
    has_field 'my_date.minute' => ( type => 'Minute' );

If you want simple input fields:

    has_field 'my_date' => ( type => 'DateTime' );
    has_field 'my_date.month' => ( type => 'Integer', range_start => 1,
         range_end => 12 );
    has_field 'my_date.day' => ( type => 'Integer', range_start => 1,
         range_end => 31 );

Customizable error: 'datetime_invalid' (default = "Not a valid DateTime")

See the 'Date' field for a single input date field.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
