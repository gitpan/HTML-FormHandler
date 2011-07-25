package HTML::FormHandler::Field::Money;
# ABSTRACT: US currency-like values

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';
our $VERSION = '0.01';

our $class_messages = {
    'money_convert' => 'Value cannot be converted to money',
    'money_real'    => 'Value must be a real number',
};

sub get_class_messages  {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}

apply(
    [
        {
            transform => sub {
                my $value = shift;
                $value =~ s/^\$//;
                return $value;
                }
        },
        {
            transform => sub { sprintf '%.2f', $_[0] },
            message => sub {
                my ( $value, $field ) = @_;
                return [$field->get_message('money_convert'), $value];
            },
        },
        {
            check => sub { $_[0] =~ /^-?\d+\.?\d*$/ },
            message => sub {
                my ( $value, $field ) = @_;
                return [$field->get_message('money_real'), $value];
            },
        }
    ]
);


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Field::Money - US currency-like values

=head1 VERSION

version 0.35001

=head1 DESCRIPTION

Validates that a postive or negative real value is entered.
Formatted with two decimal places.

Uses a period for the decimal point. Widget type is 'text'.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

