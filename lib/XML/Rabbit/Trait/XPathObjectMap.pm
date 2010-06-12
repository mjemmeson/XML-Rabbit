use strict;
use warnings;

package XML::Rabbit::Trait::XPathObjectMap;
use Moose::Role 1.05;

with 'XML::Rabbit::Trait::XPath';

# ABSTRACT: Multiple XML DOM object xpath extractor trait

around '_process_options' => sub {
    my ($orig, $self, $name, $options, @rest) = @_;

    $self->$orig($name, $options, @rest);

    # This should really be:
    # has '+isa' => ( required => 1 );
    # but for some unknown reason Moose doesn't allow that
    confess("isa attribute is required") unless defined( $options->{'isa'} );

};

=attr isa_map

Specifies the prefix:tag to class name mapping used with union xpath
queries. See L<XML::Rabbit> for more detailed information.

=cut

has 'isa_map' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    default => sub { +{} },
);

=attr xpath_key

The xpath query that specifies what will be put in the key in the hash. Required.

=cut

has 'xpath_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=method _build_default

Returns a coderef that is run to build the default value of the parent attribute. Read Only.

=cut

sub _build_default {
    my ($self) = @_;
    return sub {
        my ($parent) = @_;
        my $xpath_query = $self->_resolve_xpath_query( $parent );
        $self->_convert_isa_map( $parent );
        my $class = $self->_resolve_class();
        my %node_map;
        foreach my $node ( $self->_find_nodes($parent, $xpath_query ) ) {
            my $key = $parent->xpc->findvalue( $self->xpath_key, $node );
            $node_map{ $key } = $self->_create_instance( $parent, $class, $node );
        }
        return \%node_map;
    };
}

no Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::XPathObjectMap;
sub register_implementation { return 'XML::Rabbit::Trait::XPathObjectMap' }

1;

=head1 SYNOPSIS

    package MyXMLSyntaxNode;
    use Moose;
    with 'XML::Rabbit::Node';

    has 'persons' => (
        isa         => 'HashRef[MyXMLSyntax::Person]',
        traits      => [qw(XPathObjectMap)],
        xpath_query => './persons/*',
        xpath_key   => './@name',
    );

    no Moose;
    __PACKAGE__->meta->make_immutable();

    1;

=head1 DESCRIPTION

This module provides the extraction of multiple complex values (subtrees)
from an XML node based on an XPath query. Each subtree is used as input for
the constructor of the class specified in the isa attribute. All of the
extracted objects are then put into an arrayref which is accessible via the
parent attribute.

See L<XML::Rabbit> for a more complete example.
