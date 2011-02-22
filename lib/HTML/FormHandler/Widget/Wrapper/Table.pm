package HTML::FormHandler::Widget::Wrapper::Table;
# ABSTRACT: wrapper class for table layout

use Moose::Role;
with 'HTML::FormHandler::Widget::Wrapper::Base';

sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    my $class  = $self->render_class($result);
    my $output = "\n<tr$class>";
    if ( $self->has_flag('is_compound') ) {
        $output .= '<td>' . $self->render_label . '</td></tr>';
    }
    elsif ( !$self->has_flag('no_render_label') && length( $self->label ) > 0 ) {
        $output .= '<td>' . $self->render_label . '</td>';
    }
    if ( !$self->has_flag('is_compound') ) {
        $output .= '<td>';
    }
    $output .= $rendered_widget;
    $output .= qq{\n<span class="error_message">$_</span>} for $result->all_errors;
    if ( !$self->has_flag('is_compound') ) {
        $output .= "</td></tr>\n";
    }
    return $output;
}

use namespace::autoclean;
1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Wrapper::Table - wrapper class for table layout

=head1 VERSION

version 0.33001

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

