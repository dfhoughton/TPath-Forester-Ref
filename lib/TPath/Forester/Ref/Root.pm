package TPath::Forester::Ref::Root;

# ABSTRACT: additional behavior for the root node of a struct tree

=head1 DESCRIPTION

Some additional behavior for the root node of a struct tree. In particular, the root
keeps track of cycles and repeated references.

=cut

use v5.10;
use Moose::Role;
use namespace::autoclean;
use Scalar::Util qw(refaddr);

has _node_counts =>
  ( is => 'ro', isa => 'HashRef[HashRef]', default => sub { {} } );

# protects against cycles
sub _cycle_check {
    my ( $self, $node, $fetch ) = @_;
    return unless $node->is_ref;
    my $ra          = refaddr $node->value;
    my $node_counts = $self->_node_counts;
    my $props       = $node_counts->{$ra};
    return $props if $fetch;
    if ($props) {
        $props->{n}->_repeats(0);
        $node->_first(0);
        $node->_repeats( $props->{c} );
        $props->{c}++;
    }
    else {
        $node_counts->{$ra} = { n => $node, c => 1 };
    }
}

1;

