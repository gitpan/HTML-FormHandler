package HTML::FormHandler::Widget::Field::Role::HTMLAttributes;
# ABSTRACT: apply HTML attributes

use Moose::Role;

sub _add_html_attributes {
    my $self = shift;

    my $output = q{};
    my $html_attr = $self->html_attr;
    for my $attr ( 'readonly', 'disabled', 'style', 'title', 'tabindex' ) {
        $html_attr->{$attr} = $self->$attr if $self->$attr;
    }
    foreach my $attr ( sort keys %$html_attr ) {
        $output .= qq{ $attr="} . $html_attr->{$attr} . qq{"};
    }
    $output .= ($self->javascript ? ' ' . $self->javascript : '');
    if( $self->input_class ) {
        $output .= ' class="' . $self->input_class . '"';
    }
    return $output;
}

1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Field::Role::HTMLAttributes - apply HTML attributes

=head1 VERSION

version 0.35001

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

