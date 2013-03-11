package TPath::Forester::Ref::Expression;

# ABSTRACT: expression that converts a ref into a L<TPath::Forester::Ref::Root> before walking it

=head1 DESCRIPTION

A L<TPath::Expression> that will automatically convert plain references like
C<{ foo => [ 'a', 'b', 'c' ], bar => 1 }> into a L<TPath::Forester::Ref::Node>
tree. These expressions can also be used on C<TPath::Forester::Ref::Node> trees
directly.

=cut

use Moose;
use namespace::autoclean;
use TPath::Forester::Ref::Node;
use Scalar::Util qw(blessed);

extends 'TPath::Expression';

sub select {
    my ( $self, $node ) = @_;
    $node = wrap($node)
      unless blessed($node) && $node->isa('TPath::Forester::Ref::Node');
    $self->SUPER::select($node);
}

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

