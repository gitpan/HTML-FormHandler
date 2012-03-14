package HTML::FormHandler::Widget::Field::RadioGroup;
# ABSTRACT: radio group rendering widget


use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

sub render {
    my $self = shift;
    my $result = shift || $self->result;
    my $id = $self->id;
    my $output = '';
    $output .= "<br />" if $self->get_tag('radio_br_after');
    my $index  = 0;

    my $fif = $result->fif;
    my @label_class = ('radio');
    my $lattrs = process_attrs( { class => \@label_class } );
    foreach my $option ( @{ $self->options } ) {
        my $value = $option->{value};
        $output .= qq{\n<label$lattrs for="$id.$index">\n<input type="radio" value="}
            . $self->html_filter($value) . '" name="'
            . $self->html_name . qq{" id="$id.$index"};
        $output .= ' checked="checked"'
            if $fif eq $value;
        $output .= process_attrs($self->element_attributes($result));
        $output .= ' />';
        my $label = $option->{label};
        $label = $self->_localize($label) if $self->localize_labels;
        $output .= "\n" . $self->html_filter($label);
        $output .= "\n</label>";
        $output .= '<br />' if $self->get_tag('radio_br_after');
        $index++;
    }
    return $self->wrap_field( $result, $output );
}

1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Field::RadioGroup - radio group rendering widget

=head1 VERSION

version 0.40003

=head1 SYNOPSIS

Renders a radio group (from a 'Select' field);

Tags: radio_br_after

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

