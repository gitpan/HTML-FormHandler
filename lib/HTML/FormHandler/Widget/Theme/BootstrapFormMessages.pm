package HTML::FormHandler::Widget::Theme::BootstrapFormMessages;
# ABSTRACT: role to render form messages using Bootstrap styling

use Moose::Role;


sub render_form_messages {
    my ( $self, $result ) = @_;

    $result ||= $self->result;
    my $output = '';
    if ( $result->has_form_errors || $result->has_errors ) {
        $output = qq{\n<div class="alert alert-error">};
        my $msg = $self->error_message;
        $msg ||= 'There were errors in your form';
        $msg = $self->_localize($msg);
        $output .= qq{\n<span class="error_message">$msg</span>};
        $output .= qq{\n<span class="error_message">$_</span>}
            for $result->all_form_errors;
        $output .= "\n</div>";
    }
    elsif ( $result->validated ) {
        my $msg = $self->success_message;
        $msg ||= "Your form was successfully submitted";
        $msg = $self->_localize($msg);
        $output = qq{\n<div class="alert alert-success">};
        $output .= qq{\n<span>$msg</span>};
        $output .= "\n</div>";
    }
    if ( $self->has_info_message && $self->info_message ) {
        my $msg = $self->info_message;
        $msg = $self->_localize($msg);
        $output = qq{\n<div class="alert alert-info">};
        $output .= qq{\n<span>$msg</span>};
        $output .= "\n</div>";
    }
    return $output;
}

1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Theme::BootstrapFormMessages - role to render form messages using Bootstrap styling

=head1 VERSION

version 0.40024

=head1 DESCRIPTION

Role to render form messages using Bootstrap styling.

=head1 NAME

HTML::FormHandler::Widget::Theme::BootstrapFormMessages

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

