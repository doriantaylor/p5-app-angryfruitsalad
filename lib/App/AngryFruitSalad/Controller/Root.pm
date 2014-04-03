package App::AngryFruitSalad::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use XML::LibXML::LazyBuilder qw(DOM F P E);

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

App::AngryFruitSalad::Controller::Root - Root Controller for App::AngryFruitSalad

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 resource

=cut

sub resource :Regex(^([0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){4}[0-9A-Fa-f]{8})$) {
    my ($self, $c) = @_;
    my $uu = $c->req->captures->[0];
    if ($c->req->method =~ /GET|HEAD/) {
        $c->forward('_get_resource', [$uu]);
    }
    elsif ($c->req->method eq 'POST') {
        $c->forward('_post_resource', [$uu]);
    }
    else {
        $c->log->info('Unsupported request method ' . $c->req->method);
        $c->response->status(405);
    }
}

sub _get_resource :Private {
    my ($self, $c, $uu) = @_;

    my $m = $c->model('RDF');
    my $local = RDF::Trine::Model->temporary_model;

    my $iter = $m->get_sparql(<<EOQ);
prefix x: <urn:uuid:$uu>
construct { x: ?b ?c . ?c ?d ?e . ?f ?g ?h }
where {
 { x: ?b ?c }
 optional { ?c ?d ?e }
 optional { ?f ?g ?h; ?i x: }
}
EOQ

    $local->add_iterator($iter);
    #$c->log->debug($local->size);

    # embed the resource recursively if it begins with a blank node;
    # terminate on cycles and nonblank nodes

    # if it's a list, traverse it whether its members are blank nodes
    # or not.

    # LOL we'll do blank nodes latar

    my $doc = $self->_xhtml_rdfa($c, $local, $uu);

    #my $ser = RDF::Trine::Serializer->new('rdfxml');
    #my $str = $ser->serialize_model_to_string($local);

    #$c->res->content_type('text/plain');
    $c->res->content_type('application/xhtml+xml');
    $c->res->body($doc->toString(1));
}

sub _dl_out {
    my ($model, $s) = @_;

    my %op;
    my $iter = $model->get_statements($s, undef, undef);
    while (my $stmt = $iter->next) {
        my $p = $stmt->predicate;
        my $x = $op{$p->value} ||= [];
        push @$x, $stmt->object;
    }

    my @out;
    for my $k (sort keys %op) {
        # click on dt to 
        push @out, (E dt => {}, $k);
        for my $i (sort { $a->value cmp $b->value } @{$op{$k}}) {
            my $val = $i->value;
            if ($i->is_resource) {
                my $href = $val;
                my $label = $val;
                if ($href =~ /urn:uuid:(.*)/) {
                    $href = "/$1";
                }
                $val = E a => { href => $href }, $label;
            }
            push @out, (E dd => {}, $val);
        }
    }

    E dl => {}, @out;
}

sub _xhtml_rdfa {
    my ($self, $c, $model, $uu) = @_;

    my $s = RDF::Trine::Node::Resource->new('urn:uuid:' . $uu);

    my %ip;
    my $iter = $model->get_statements(undef, undef, $s);
    while (my $stmt = $iter->next) {
        my $p = $stmt->predicate;
        my $x = $ip{$p->value} ||= [];
        push @$x, $stmt->subject;
    }

    my %op;
    $iter = $model->get_statements($s, undef, undef);
    while (my $stmt = $iter->next) {
        my $p = $stmt->predicate;
        my $x = $op{$p->value} ||= [];
        push @$x, $stmt->object;
    }

    my @in;
    for my $k (sort keys %ip) {
        for my $i (sort { $a->value cmp $b->value } @{$ip{$k}}) {
            my $val = $i->value;
            if ($i->is_resource) {
                my $href = $val;
                my $label = $val;
                if ($href =~ /urn:uuid:(.*)/) {
                    $href = $1;
                }
                $val = E a => { href => $href }, $label;
            }
            push @in, (E dd => {}, $val);
        }

        push @in, (E dt => {}, $k);
    }

    my @out;
    for my $k (sort keys %op) {
        # click on dt to 
        push @out, (E dt => {}, $k);
        for my $i (sort { $a->value cmp $b->value } @{$op{$k}}) {
            my $val = $i->value;
            if ($i->is_resource) {
                my $href = $val;
                my $label = $val;
                if ($href =~ /urn:uuid:(.*)/) {
                    $href = "/$1";
                }
                $val = E a => { href => $href }, $label;
            }
            push @out, (E dd => {}, $val);
        }
    }

    return DOM E html => { xmlns => 'http://www.w3.org/1999/xhtml' },
        (E head => {},
         E title => {}),
             (E body => {},
              (E aside => { class => 'inbound' },
               (E h2 => {}, 'What links here'),
               (E dl => {}, @in)),
              (E section => { class => 'properties' },
               (E h2 => {}, 'Properties'),
               (E dl => {}, @out)));

    require Data::Dumper;
    $c->log->debug(Data::Dumper::Dumper(\%op));

}

sub _post_resource :Private {
    my ($self, $c, $uu) = @_;
    $c->res->body($uu);
}

sub class :Local {
    my ($self, $c, $prefix, $class) = @_;

    $c->log->debug("$prefix:$class");

    my $m = $c->model('RDF');
    my $local = RDF::Trine::Model->temporary_model;

    my $iter = $m->get_sparql(<<EOQ);
construct { ?s ?p ?o }
where { ?s a $prefix:$class . ?s ?p ?o }
EOQ

    my %s;
    while (my $stmt = $iter->next) {
        $local->add_statement($stmt);
        my $s = $stmt->subject;
        $s{$s->value} ||= $s;
    }

    my @div;
    for my $k (sort keys %s) {
        my $s = $s{$k};
        my $val = $s->value;
        if ($s->is_resource) {
            my $href = $val;
            my $label = $val;
            if ($href =~ /urn:uuid:(.*)/) {
                $href = "/$1";
            }
            $val = E a => { href => $href }, $label;
        }
        push @div, (E div => {}, (E h2 => {}, $val), _dl_out($local, $s));
    }

    my $doc = DOM E html => { xmlns => 'http://www.w3.org/1999/xhtml' },
        (E head => {},
         E title => {}),
             (E body => {},
              (E main => {}, @div));

    $c->res->content_type('application/xhtml+xml');
    $c->res->body($doc->toString(1));
}

sub in_range_of :Path(in-range-of) {
    my ($self, $c, $prefix, $term) = @_;


}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
