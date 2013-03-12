package TPath::Forester::Ref;

# ABSTRACT: L<TPath::Forester> that understands Perl structs

=head1 SYNOPSIS

  use TPath::Forester::Ref;
  use Data::Dumper;
  
  my $ref = {
      a => [],
      b => {
          g => undef,
          h => { i => [ { l => 3, 4 => 5 }, 2 ], k => 1 },
          c => [qw(d e f)]
      }
  };
  
  my @hashes = tfr->path(q{//@hash})->dsel($ref);
  print scalar @hashes, "\n"; # 3
  my @arrays = tfr->path(q{//@array})->dsel($ref);
  print scalar @arrays, "\n"; # 3
  print Dumper $arrays[2];    # hash keys are sorted alphabetically
  # $VAR1 = [
  #           {
  #             'l' => 3,
  #             '4' => 5
  #           },
  #           2
  #         ];
  
=head1 DESCRIPTION

C<TPath::Forester::Ref> adapts L<TPath::Forester> to run-of-the-mill Perl
data structures.

=cut

use v5.10;
use Moose;
use Moose::Util qw(apply_all_roles);
use Moose::Exporter;
use MooseX::MethodAttributes;
use namespace::autoclean;
use TPath::Forester::Ref::Node;
use TPath::Forester::Ref::Expression;

Moose::Exporter->setup_import_methods( as_is => [ tfr => \&tfr ], );

=head1 ROLES

L<TPath::Forester>

=cut

with 'TPath::Forester' => { -excludes => 'wrap' };

sub children {
    my ( $self, $n ) = @_;
    @{ $n->children };
}

sub tag { $_[1]->tag }

sub matches_tag {
    my ( $self, $n, $re ) = @_;
    return 0 unless defined $n->tag;
    $n->tag =~ $re;
}

=method C<@array>

Whether the node is an array ref.

=cut

sub array : Attr { my ( $self, $n ) = @_; $n->type eq 'array' ? 1 : undef; }

=method C<@can('method')>

Attribute that is defined if the node in question has the specified method.

=cut

sub obj_can : Attr(can) {
    my ( $self, $n, undef, undef, $method ) = @_;
    $n->type eq 'object' && $n->value->can($method) ? 1 : undef;
}

=method C<@code>

Attribute that is defined if the node is a code reference.

=cut

sub code : Attr { my ( $self, $n ) = @_; $n->type eq 'code' ? 1 : undef; }

=method C<@defined>

Attribute that is defined if the node is a defined value.

=cut

sub obj_defined :
  Attr(defined) { my ( $self, $n ) = @_; defined $n->value ? 1 : undef; }

=method C<@does('role')>

Attribute that is defined if the node does the specified role.

=cut

sub obj_does : Attr(does) {
    my ( $self, $n, undef, undef, $role ) = @_;
    $n->type eq 'object' && $n->value->does($role) ? 1 : undef;
}

=method C<@glob>

Attribute that is defined if the node is a glob reference.

=cut

sub glob : Attr { my ( $self, $n ) = @_; $n->type eq 'glob' ? 1 : undef; }

=method C<@hash>

Attribute that is defined if the node is a hash reference.

=cut

sub hash : Attr { my ( $self, $n ) = @_; $n->type eq 'hash' ? 1 : undef; }

=method C<@isa('Foo','Bar')>

Attribute that is defined if the node instantiates any of the specified classes.

=cut

sub obj_isa : Attr(isa) {
    my ( $self, $n, undef, undef, @classes ) = @_;
    return undef unless $n->type eq 'object';
    for my $class (@classes) {
        return 1 if $n->value->isa($class);
    }
    undef;
}

=method C<@key>

Attribute that returns the hash key, if any, associated with the node value.

=cut

sub key : Attr { $_[1]->tag }

=method C<@num>

Attribute defined for nodes whose value looks like a number according to L<Scalar::Util>.

=cut

sub num : Attr { my ( $self, $n ) = @_; $n->type eq 'num' ? 1 : undef; }

=method C<@obj>

Attribute that is defined for nodes holding objects.

=cut

sub obj : Attr { my ( $self, $n ) = @_; $n->type eq 'object' ? 1 : undef; }

=method C<@ref>

Attribute defined for nodes holding references such as C<{}> or C<[]>.

=cut

sub is_ref : Attr(ref) { my ( $self, $n ) = @_; $n->is_ref ? 1 : undef; }

=method C<@non-ref>

Attribute that is defined for nodes holding non-references -- C<undef>, strings,
or numbers.

=cut

sub is_non_ref :
  Attr(non-ref) { my ( $self, $n ) = @_; $n->is_ref ? undef : 1; }

=method C<@repeat> or C<@repeat(1)>

Attribute that is defined if the node holds a reference that has occurs earlier
in the tree. If a parameter is supplied, it is defined if the node in question
is the specified repetition of the reference, where the first instance is repetition
0.

=cut

sub repeat : Attr {
    my ( $self, $n, undef, undef, $index ) = @_;
    my $reps = $n->is_repeated;
    return undef unless defined $reps;
    return $reps ? 1 : undef unless defined $index;
    $n->is_repeated == $index ? 1 : undef;
}

=method C<@repeated>

Attribute that is defined for any node holding a reference that occurs more than once
in the tree.

=cut

sub repeated :
  Attr { my ( $self, $n ) = @_; defined $n->is_repeated ? 1 : undef; }

=method C<@scalar>

Attribute that is defined for any node holding a scalar reference.

=cut

sub is_scalar :
  Attr(scalar) { my ( $self, $n ) = @_; $n->type eq 'scalar' ? 1 : undef; }

=method C<@str>

Attribute that is defined for any node holding a string.

=cut

sub str : Attr { my ( $self, $n ) = @_; $n->type eq 'string' ? 1 : undef; }

=method C<@undef>

Attribute that is defined for any node holding the C<undef> value.

=cut

sub is_undef :
  Attr(undef) { my ( $self, $n ) = @_; $n->type eq 'undef' ? 1 : undef; }

=method wrap

Takes a reference and converts it into a tree, overriding L<TPath::Forester>'s no-op C<wrap>
method.

  my $tree = tfr->wrap(
      { foo => bar, baz => [qw(1 2 3 4)], qux => { quux => { corge => undef } } }
  );

This is useful if you are going to be doing multiple selections from a single
struct and want to use a common index. If you B<don't> use C<rtree> to work off
a common object your index will give strange results as it won't be able to
find the parents of your nodes.

=cut

{
    no warnings 'redefine';

    sub wrap {
        my ( $self, $n ) = @_;
        return $n if blessed($n) && $n->isa('TPath::Forester::Ref::Node');
        coerce($n);
    }
}

around path => sub {
    my ( $orig, $self, $expr ) = @_;
    my $path = $self->$orig($expr);
    bless $path, 'TPath::Forester::Ref::Expression';
};

sub coerce {
    my ( $ref, $root, $tag ) = @_;
    my $node;
    if ($root) {
        $node = TPath::Forester::Ref::Node->new(
            value => $ref,
            _root => $root,
            tag   => $tag,
        );
    }
    else {
        $root = TPath::Forester::Ref::Node->new( value => $ref, tag => undef );
        apply_all_roles( $root, 'TPath::Forester::Ref::Root' );
        $root->_add_root($root);
        $node = $root;
    }
    $root->_cycle_check($node);
    return $node if $node->is_repeated;
    for ( $node->type ) {
        when ('hash') {
            for my $key ( sort keys %$ref ) {
                push @{ $node->children }, coerce( $ref->{$key}, $root, $key );
            }
        }
        when ('array') {
            push @{ $node->children }, coerce( $_, $root ) for @$ref;
        }
    }
    return $node;
}

=func tfr

Returns singleton C<TPath::Forester::Ref>.

=cut

sub tfr() { state $singleton = TPath::Forester::Ref->new }

__PACKAGE__->meta->make_immutable;

1;
