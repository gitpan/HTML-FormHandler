package HTML::FormHandler::Widget::Wrapper::Bootstrap;
# ABSTRACT: Twitter Bootstrap 2.0 field wrapper

use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

with 'HTML::FormHandler::Widget::Wrapper::Base';



sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    my $output;
    # is this a control group or a form action?
    my $form_actions = 1 if ( $self->name eq 'form_actions' || $self->type_attr eq 'submit'
        || $self->type_attr eq 'reset' );
    # create attribute string for wrapper
    my $attr = $self->wrapper_attributes($result);
    my $div_class = $form_actions ? "form-actions" : "control-group";
    unshift @{$attr->{class}}, $div_class;
    my $attr_str = process_attrs( $attr );
    # wrapper is always a div
    $output .= qq{\n<div$attr_str>}
        if $self->do_wrapper;
    # render the label
    $output .= "\n" . $self->do_render_label($result, undef, ['control-label'] )
        if $self->do_label;
    $output .=  $self->get_tag('before_element');
    # the controls div for ... controls
    $output .= qq{\n<div class="controls">} unless $form_actions || !$self->do_label;
    # handle input-prepend and input-append
    if( my $ip_tag = $self->get_tag('input_prepend' ) ) {
        $rendered_widget = $self->input_prepend($rendered_widget, $ip_tag);
    }
    elsif ( my $ia_tag = $self->get_tag('input_append' ) ) {
        $rendered_widget = $self->input_append($rendered_widget, $ia_tag);
    }
    elsif( lc $self->widget eq 'checkbox' ) {
        $rendered_widget = $self->wrap_checkbox($result, $rendered_widget, 'label')
    }

    $output .= "\n$rendered_widget";
    # various 'help-inline' bits: errors, warnings
    unless( $self->get_tag('no_errors') ) {
        $output .= qq{\n<span class="help-inline">$_</span>}
            for $result->all_errors;
        $output .= qq{\n<span class="help-inline">$_</span>} for $result->all_warnings;
    }
    # extra after element stuff
    $output .= $self->get_tag('after_element');
    # close 'control' div
    $output .= '</div>' unless $form_actions || !$self->do_label;
    # close wrapper
    $output .= "\n</div>" if $self->do_wrapper;
    return "$output";
}

sub input_prepend {
    my ( $self, $rendered_widget, $ip_tag ) = @_;
    my $rendered =
qq{<div class="input-prepend">
  <span class="add-on">$ip_tag</span>
  $rendered_widget
</div>};
    return $rendered;
}

sub input_append {
    my ( $self, $rendered_widget, $ia_tag ) = @_;
    my $rendered =
qq{<div class="input-append">
  $rendered_widget
  <span class="add-on">$ia_tag</span>
</div>};
    return $rendered;
}

1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Wrapper::Bootstrap - Twitter Bootstrap 2.0 field wrapper

=head1 VERSION

version 0.40008

=head1 SYNOPSIS

Wrapper to implement Bootstrap 2.0 style form element rendering. This wrapper
does some very specific Bootstrap things, like wrap the form elements
in divs with non-changeable classes. It is not as flexible as the
'Simple' wrapper, but means that you don't have to specify those classes
in your form code.

It wraps form elements with 'control-group' divs, and form 'actions' with
'form-actions' divs. It adds special additional wrappers for checkboxes and radio
buttons, with wrapped labels.

=head1 DESCRIPTION

Tags supported:

   label_no_filter -- don't html filter the label
   label_after -- useful for putting a colon, or other trailing formatting
   before_element -- insert tag before input element
   input_prepend -- for Bootstrap 'input-prepend' class
   input_append -- for Bootstrap 'input-append' class
   no_errors -- don't append error to field rendering
   after_element -- insert tag after input element

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

