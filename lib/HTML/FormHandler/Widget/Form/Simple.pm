package HTML::FormHandler::Widget::Form::Simple;
# ABSTRACT: widget to render a form with divs

use Moose::Role;
use HTML::FormHandler::Render::Util ('process_attrs');

with 'HTML::FormHandler::Widget::Form::Role::HTMLAttributes';
our $VERSION = 0.01;


sub render {
    my ($self) = @_;

    my $result;
    my $form;
    if ( $self->DOES('HTML::FormHandler::Result') ) {
        $result = $self;
        $form   = $self->form;
    }
    else {
        $result = $self->result;
        $form   = $self;
    }
    my $output = $form->render_start($result);
    $output .= $form->render_form_messages($result);

    if ( $form->has_render_list ) {
        foreach my $fb ( @{ $form->render_list } ) {
            # it's a Field
            if ( $self->field_in_index($fb) ) {
                # find field result and use that
                my $fld_result = $result->get_result($fb);
                # if no result, then we shouldn't be rendering this field
                next unless $fld_result;
                $output .= $fld_result->render;
            }
            # it's a Block
            else {
                # always use form level result for blocks
                my $block = $self->block($fb);
                die "found no form field or block named '$fb'\n" unless $block;
                $output .= $block->render($result);
            }
        }
    }
    else {
        foreach my $fld_result ( $result->results ) {
            $output .= $fld_result->render;
        }
    }

    $output .= $form->render_end($result);
    return $output;
}

sub render_start {
    my ( $self, $result ) = @_;
    $result ||= $self->result;

    my $output = '';
    $output = $self->get_tag('before');
    if( $self->do_form_wrapper ) {
        my $form_wrapper_tag = $self->get_tag('wrapper_tag') || 'fieldset';
        my $attrs = process_attrs($self->form_wrapper_attributes($result));
        $output .= qq{<$form_wrapper_tag$attrs>};
    }
    my $attrs = process_attrs($self->attributes($result));
    $output .= qq{<form$attrs>};
    $output .= $self->get_tag('after_start');

    return $output
}

sub render_form_errors { shift->render_form_messages(@_) }
sub render_form_messages {
    my ( $self, $result ) = @_;
    $result ||= $self->result;

    return '' if $self->get_tag('no_form_message_div');
    my $messages_wrapper_class = $self->get_tag('messages_wrapper_class') || 'form_messages';
    my $output = qq{\n<div class="$messages_wrapper_class">};
    my $error_class = $self->get_tag('error_class') || 'error_message';
    if( $self->has_error_message && ( $result->has_errors || $result->has_form_errors ) ) {
        my $msg = $self->error_message;
        $msg = $self->_localize($msg);
        $output .= qq{\n<span class="$error_class">$msg</span>};
    }
    if ( $result->has_form_errors ) {
        $output .= qq{\n<span class="$error_class">$_</span>}
            for $result->all_form_errors;
    }
    if( $self->has_success_message && $result->validated ) {
        my $msg = $self->success_message;
        $msg = $self->_localize($msg);
        my $success_class = $self->get_tag('success_class') || 'success_message';
        $output .= qq{\n<span class="$success_class">$msg</span>};
    }
    $output .= "\n</div>";
    return $output;
}

sub render_end {
    my $self = shift;

    my $output = $self->get_tag('before_end');
    $output .= "\n</form>";
    if( $self->do_form_wrapper) {
        my $form_wrapper_tag = $self->get_tag('wrapper_tag') || 'fieldset';
        $output .= qq{\n</$form_wrapper_tag>};
    }
    $output .= $self->get_tag('after');
    $output .= "\n";
    return $output;
}
use namespace::autoclean;
1;


__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Form::Simple - widget to render a form with divs

=head1 VERSION

version 0.40000

=head1 SYNOPSIS

Role to apply to form objects to allow rendering. This rendering
role is applied to HTML::FormHandler by default. It supports block
rendering. (L<HTML::FormHandler::Blocks>, L<HTML::FormHandler::Widget::Block>)

Relevant flags:

    do_form_wrapper - put a wrapper around the form

Supported tags:

    wrapper_tag -- tag for form wrapper; default 'fieldset'
    before
    after
    after_start
    before_end

    messages_wrapper_class -- default 'form_messages'
    error_class -- default 'error_message'
    error_message -- message to issue when form contains errors
    success_class -- default 'success_message'
    success_message -- message to issue when form was submitted successfully

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

