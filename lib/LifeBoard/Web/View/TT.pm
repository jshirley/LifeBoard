package LifeBoard::Web::View::TT;

use strict;
use base 'Catalyst::View::TT';

use Scalar::Util 'blessed';
use DateTime::Format::DateParse;

__PACKAGE__->config({
    PRE_PROCESS        => 'site/shared/base.tt',
    WRAPPER            => 'site/wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    TIMER              => 0,
    static_root        => '/static',
    static_build       => 20100701,
    default_tz          => 'America/Los_Angeles',
    default_locale      => 'en_US',
    formats             => {
        date => {
            iso     => '%F',
            date    => '%x',
            short   => '%b %e, %G',
            medium  => '%b %e, %G %l:%M %p',
            long    => '%X %x',
            hour    => '%l:%M %p'
        }
    }
});

sub template_vars {
    my $self = shift;
    return (
        $self->next::method(@_),
        static_root  => $self->{static_root},
        static_build => $self->{static_build}
    );
}

sub process {
    my ( $self, $c, @rest ) = @_;
    my $ret = $self->next::method($c, @rest);
    $c->res->content_type('text/html')
        if $c->res->content_type =~ /(xml|xhtml|www-form-urlencoded)/;
    return $ret;
}


sub new {
    my ( $class, $c, $arguments ) = @_;
    my $formats = $class->config->{formats};

    return $class->next::method( $c, $arguments ) unless ref $formats eq 'HASH';

    $class->config->{FILTERS} ||= {};

    my $filters = $class->config->{FILTERS};

    foreach my $key ( keys %$formats ) {
        if ( $key eq 'date' ) {
            foreach my $date_key ( keys %{$formats->{$key}} ) {
                $filters->{"${key}_$date_key"} = sub {
                    my $date = shift;
                    return unless defined $date;
                    unless ( blessed $date and $date->can("stringify") ) {
                        $date = DateTime::Format::DateParse->parse_datetime($date);
                    }
                    unless ( $date ) { return $date; }
                    $date->set_locale($class->config->{default_locale})
                        if defined $class->config->{default_locale};
                    # Only apply a timezone if we have a complete date.
                    unless ( "$date" =~ /T00:00:00$/ ) {
                        $date->set_time_zone( $class->config->{default_tz} || 'America/Los_Angeles' );
                    }
                    $date->strftime($formats->{$key}->{$date_key});
                };
            }
        }
    }

    return $class->next::method( $c, $arguments );
}

1;
