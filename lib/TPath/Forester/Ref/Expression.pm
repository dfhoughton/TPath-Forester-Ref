package TPath::Forester::Ref::Expression;

# ABSTRACT: expression that converts a ref into a L<TPath::Forester::Ref::Root> before walking it

=head1 DESCRIPTION

A L<TPath::Expression> that provides the C<dsel> method.

=cut

use Moose;
use namespace::autoclean;

extends 'TPath::Expression';

=method dsel

"De-references" the values selected by the path, extracting them from the
L<TPath::Forester::Ref::Node> objects that hold them.

In an array context C<dsel> returns all selections. Otherwise, it returns
the first node selected.

=cut

sub dsel {
    my ( $self, $node ) = @_;
    my @selection = $self->select($node);
    return $selection[0] unless wantarray;
    map { $_->value } $self->select($node);
}

__PACKAGE__->meta->make_immutable;

1;

