package HTML::FormHandler::Widget::Field::CheckboxGroup;
# ABSTRACT: checkbox group field role

use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');


sub render_element {
    my ( $self, $result ) = @_;
    $result ||= $self->result;

    my $output = '';
    my $index  = 0;
    my $multiple = $self->multiple;
    my $id = $self->id;
    my $ele_attributes = process_attrs($self->element_attributes($result));

    my $fif = $result->fif;
    my %fif_lookup;
    @fif_lookup{@$fif} = () if $multiple;
    my @option_label_class = ('checkbox');
    push @option_label_class, 'inline' if $self->get_tag('inline');
    my $opt_lattrs = process_attrs( { class => \@option_label_class } );
    foreach my $option ( @{ $self->{options} } ) {
        $output .= qq{\n<label$opt_lattrs for="$id.$index">};
        my $value = $option->{value};
        $output .= qq{\n<input type="checkbox" value="}
            . $self->html_filter($value) . '" name="'
            . $self->html_name . qq{" id="$id.$index"};
        if( defined $option->{disabled} && $option->{disabled} ) {
            $output .= 'disabled="disabled" ';
        }
        if ( defined $fif ) {
            if ( $multiple && exists $fif_lookup{$value} ) {
                $output .= ' checked="checked"';
            }
            elsif ( $fif eq $value ) {
                $output .= ' checked="checked"';
            }
        }
        $output .= $ele_attributes;
        my $label = $option->{label};
        $label = $self->_localize($label) if $self->localize_labels;
        $output .= " />\n" . ( $self->html_filter($label) || '' );
        $output .= "\n</label>";
        $index++;
    }
    return $output;
}

sub render {
    my ( $self, $result ) = @_;
    $result ||= $self->result;
    my $output = $self->render_element( $result );
    return $self->wrap_field( $result, $output );
}

1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Widget::Field::CheckboxGroup - checkbox group field role

=head1 VERSION

version 0.40007

=head1 SYNOPSIS

Checkbox group widget for rendering multiple selects.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

