package App::AngryFruitSalad;
use Moose;
use namespace::autoclean;

use RDF::Trine;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
/;
#    +CatalystX::Profile

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in app_angryfruitsalad.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'App::AngryFruitSalad',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
);

# Start the application
__PACKAGE__->setup();


sub temp_model {
    # hexastore is fastest by far even though i bet it could be made faster
    my $store = RDF::Trine::Store::Hexastore->new;
    # my $store = RDF::Trine::Store->new_with_config({
    #     storetype => 'Redland',
    #     store_name => 'memory',
    #     name => 'derp',
    #     options => { contexts => 1 },
    # }) or die $!;

    RDF::Trine::Model->new($store);
}

=head1 NAME

App::AngryFruitSalad - Catalyst based application

=head1 SYNOPSIS

    script/app_angryfruitsalad_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<App::AngryFruitSalad::Controller::Root>, L<Catalyst>

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
