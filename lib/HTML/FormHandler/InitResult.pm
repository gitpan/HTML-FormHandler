package HTML::FormHandler::InitResult;

use Moose::Role;

=head1 NAME

HTML::FormHandler::InitResult

=head1 SYNOPSIS

Internal role for initializing the result objects.

=cut

# _init is for building fields when
# there is no initial object and no params
# formerly _init
sub _result_from_fields {
    my ( $self, $self_result ) = @_;
    for my $field ( $self->sorted_fields ) {
        next if $field->inactive;
        my $result = HTML::FormHandler::Field::Result->new(
            name   => $field->name,
            parent => $self_result
        );
        $result = $field->_result_from_fields($result);
        $self_result->add_result($result) if $result;
    }
    $self->_set_result($self_result);
    $self_result->_set_field_def($self) if $self->DOES('HTML::FormHandler::Field');
    return $self_result;
}

# building fields from input (params)
# formerly done in validate_field
sub _result_from_input {
    my ( $self, $self_result, $input, $exists ) = @_;

    # transfer the input values to the input attributes of the
    # subfields
    return unless ( defined $input || $exists || $self->has_fields );
    $self_result->_set_input($input);
    if ( ref $input eq 'HASH' ) {
        foreach my $field ( $self->sorted_fields ) {
            next if $field->inactive;
            my $field_name = $field->name;
            my $result     = HTML::FormHandler::Field::Result->new(
                name   => $field_name,
                parent => $self_result
            );
            $result =
                $field->_result_from_input( $result, $input->{$field_name},
                exists $input->{$field_name} );
            $self_result->add_result($result) if $result;
        }
    }
    $self->_set_result($self_result);
    $self_result->_set_field_def($self) if $self->DOES('HTML::FormHandler::Field');
    return $self_result;
}

# building fields from model object or init_obj hash
# formerly _init_from_object
sub _result_from_object {
    my ( $self, $self_result, $item ) = @_;

    return unless ( $item || $self->has_fields );    # empty fields for compounds
    my $my_value;
    for my $field ( $self->sorted_fields ) {
        next if $field->inactive;
        my $result = HTML::FormHandler::Field::Result->new(
            name   => $field->name,
            parent => $self_result
        );
        if ( ref $item eq 'HASH' && !exists $item->{ $field->accessor } ) {
            $result = $field->_result_from_fields($result);
        }
        else {
            my $value = $self->_get_value( $field, $item );
            $result = $field->_result_from_object( $result, $value );
        }
        $self_result->add_result($result) if $result;
        $my_value->{ $field->name } = $field->value;
    }
    $self_result->_set_value($my_value);
    $self->_set_result($self_result);
    $self_result->_set_field_def($self) if $self->DOES('HTML::FormHandler::Field');
    return $self_result;
}

sub _get_value {
    my ( $self, $field, $item ) = @_;
    my $accessor = $field->accessor;
    my @values;
    if ( blessed($item) && $item->can($accessor) ) {
        @values = $item->$accessor;
    }
    elsif ( exists $item->{$accessor} ) {
        @values = $item->{$accessor};
    }
    else {
        return;
    }
    my $value = @values > 1 ? \@values : shift @values;
    return $value;
}

=head1 AUTHORS

HTML::FormHandler Contributors; see HTML::FormHandler

Initially based on the original source code of L<Form::Processor::Field> by Bill Moseley

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

use namespace::autoclean;
1;
