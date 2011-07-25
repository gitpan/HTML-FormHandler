package HTML::FormHandler::Field::TextArea;
# ABSTRACT: textarea input

use Moose;
extends 'HTML::FormHandler::Field';
our $VERSION = '0.01';

has '+widget' => ( default => 'textarea' );
has 'cols'    => ( isa     => 'Int', is => 'rw' );
has 'rows'    => ( isa     => 'Int', is => 'rw' );


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Field::TextArea - textarea input

=head1 VERSION

version 0.35001

=head1 Summary

For HTML textarea. Uses 'textarea' widget. Set cols/row.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

