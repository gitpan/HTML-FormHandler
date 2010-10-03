package HTML::FormHandler::Field::Password;
# ABSTRACT: password field

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';
our $VERSION = '0.04';


has '+widget'           => ( default => 'password' );
has '+password'         => ( default => 1 );
has '+required_message' => ( default => 'Please enter a password in this field' );
has 'ne_username'       => ( isa     => 'Str', is => 'rw' );

after 'validate_field' => sub {
    my $self = shift;

    if ( !$self->required && !( defined( $self->value ) && length( $self->value ) ) ) {
        $self->noupdate(1);
        $self->clear_errors;
    }
};

sub validate {
    my $self = shift;

    $self->noupdate(0);
    return unless $self->next::method;

    my $value = $self->value;
    if ( $self->form && $self->ne_username ) {
        my $username = $self->form->get_param( $self->ne_username );
        return $self->add_error( 'Password must not match ' . $self->ne_username )
            if $username && $username eq $value;
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Field::Password - password field

=head1 VERSION

version 0.32003

=head1 DESCRIPTION

The password field has a default minimum length of 6, which can be
easily changed:

  has_field 'password' => ( type => 'Password', minlength => 7 );

It does not come with additional default checks, since password
requirements vary so widely. There are a few constraints in the
L<HTML::FormHandler::Types> modules which could be used with this
field:  NoSpaces, WordChars, NotAllDigits.
These constraints can be used in the field definitions 'apply':

   use HTML::FormHandler::Types ('NoSpaces', 'WordChars', 'NotAllDigits' );
   ...
   has_field 'password' => ( type => 'Password',
          apply => [ NoSpaces, WordChars, NotAllDigits ],
   );

You can add your own constraints in addition, of course.

If a password field is not required, then the field will be marked 'noupdate',
to prevent a null from being saved into the database.

=head2 ne_username

Set this attribute to the name of your username field (default 'username')
if you want to check that the password is not the same as the username.
Does not check by default.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

