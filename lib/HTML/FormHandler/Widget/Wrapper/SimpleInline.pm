package HTML::FormHandler::Widget::Wrapper::SimpleInline;
# ABSTRACT: simple field wrapper

use Moose::Role;
use namespace::autoclean;

with 'HTML::FormHandler::Widget::Wrapper::Base';


has 'auto_fieldset' => ( isa => 'Bool', is => 'rw', lazy => 1, default => 1 );

sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    return $rendered_widget if $self->has_flag('is_compound');

    my $t;
    my $output = '';
    my $start_tag = defined($t = $self->get_tag('wrapper_start')) ?
        $t : '<div<%class%>>';
    my $class  = $self->render_class($result);
    $output .= "\n";
    $start_tag =~ s/<%class%>/$class/g;
    $output .= $start_tag;

    if ( !$self->has_flag('no_render_label') && length( $self->label ) > 0 ) {
        $output .= $self->render_label;
    }

    $output .= $rendered_widget;
    $output .= qq{\n<span class="error_message">$_</span>}
        for $result->all_errors;

    $output .= defined($t = $self->get_tag('wrapper_end')) ? $t : '</div>';

    return "$output\n";
}

1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Wrapper::SimpleInline - simple field wrapper

=head1 VERSION

version 0.35002

=head1 SYNOPSIS

This works like the Simple Wrapper, except it doesn't wrap Compound
fields.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

