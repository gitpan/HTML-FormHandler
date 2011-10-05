package HTML::FormHandler::TraitFor::Types;
use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'HFH::ArrayRefStr'
  => as 'ArrayRef[Str]';

coerce 'HFH::ArrayRefStr'
  => from 'Str'
  => via { 
         if( length $_ ) { return [$_] };
         return []; 
     };

coerce 'HFH::ArrayRefStr'
  => from 'Undef'
  => via { return []; };

no Moose::Util::TypeConstraints;
1;

__END__
=pod

=head1 NAME

HTML::FormHandler::TraitFor::Types

=head1 VERSION

version 0.35004

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

