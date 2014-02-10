package HTML::FormHandler::Pages;
# ABSTRACT: used in Wizard

use Moose::Role;

has 'pages' => (
    traits     => ['Array'],
    isa        => 'ArrayRef[HTML::FormHandler::Page]',
    is         => 'rw',
    default    => sub { [] },
    auto_deref => 1,
    handles   => {
        all_pages => 'elements',
        clear_pages => 'clear',
        push_page => 'push',
        num_pages => 'count',
        has_pages => 'count',
        set_page_at => 'set',
        get_page => 'get',
    }
);

has 'page_name_space' => (
    isa     => 'Str|ArrayRef[Str]|Undef',
    is      => 'rw',
    lazy    => 1,
    builder => 'build_page_name_space',
);

sub build_page_name_space { '' }

sub page_index {
    my ( $self, $name ) = @_;
    my $index = 0;
    for my $page ( $self->all_pages ) {
        return $index if $page->name eq $name;
        $index++;
    }
    return;
}

sub page {
    my ( $self, $name, $die ) = @_;

    my $index;
    # if this is a full_name for a compound page
    # walk through the pages to get to it
    return undef unless ( defined $name );
    if ( $name =~ /\./ ) {
        my @names = split /\./, $name;
        my $f = $self->form || $self;
        foreach my $pname (@names) {
            $f = $f->page($pname);
            return unless $f;
        }
        return $f;
    }
    else    # not a compound name
    {
        for my $page ( $self->all_pages ) {
            return $page if ( $page->name eq $name );
        }
    }
    return unless $die;
    die "Page '$name' not found in '$self'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Pages - used in Wizard

=head1 VERSION

version 0.40056

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
