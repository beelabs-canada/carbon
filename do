package Carbon;

use common::sense;
use HTTP::Tiny;
use Data::Dmp;

our $VERSION = '1.0 alpha';

sub new {
    return bless [ Carbon::Enviroment->new ], shift;
}

sub run {
    my ($self) = shift;

    foreach my $action ( $self->[0]->actions ) {
        my ($task) = keys $action;

        my $target =
          ( exists $action->{$task}->{'target'} )
          ? delete $action->{$task}->{'target'}
          : undef;

        if ( !defined $target ) {
            $self->exec( ucfirst($task), $action->{$task} );
            next;
        }

        if ( $self->[0]->os =~ m/\b$target\b/ ) {
            $self->exec( ucfirst($task), $action->{$task} );
        }
    }
}

sub exec {
    my ( $self, $task, $props ) = @_;
    return "Carbon::$task"->new($props)->do( $self->[0]->basedir );
}

# CLI
# ---------------------------------------
(
    sub {
        say "   ##########################################";
        say "   #   Carbon Runner ($VERSION)";
        say "   #   \@author Mario Bonito";
        say "   ##########################################";
        
        Carbon->new()->run();
        
        say "   ...completed (OK)";
    }
)->()
  if not caller();

# #######################################
# # CARBON::ENVIROMENT
# #######################################
package Carbon::Enviroment;


use YAML::XS 'LoadFile';
use Path::Tiny;

use constant { INSTRUCTS => 0, OS => 1, BASEDIR => 2 };

sub new {
    return bless [
        ( -e $0 . '.yml' ) ?  LoadFile ( $0 . '.yml' ) : [],
        "$^O",
        path($0)->parent
      ],
      shift;
}

sub actions { @{ shift->[INSTRUCTS] } }
sub basedir { shift->[BASEDIR] }
sub os      { shift->[OS] }

# #######################################
# # CARBON::FETCH
# #######################################
package Carbon::Pluck;

use HTTP::Tiny;
use Path::Tiny;
use File::Basename;
use Archive::Extract;

sub new {
    my ( $class, $props, $basedir ) = @_;

    return bless [
        HTTP::Tiny->new(
            agent   => 'Carbon Task Agent v1.*',
            timeout => 20,
            %{ delete $props->{'http'} }
        ),
        $props
    ], $class;
}

sub do {
    my ( $self, $basedir ) = @_;

    my ( $http, $uri, $temp ) =
      ( $self->[0], $self->[1]->{'uri'}, Path::Tiny->tempdir() );

    my $archive = $temp->child( basename($uri) );
    
    say "   [pluck] downloading $uri";
    
    $http->mirror( $uri, $archive->stringify );

    my $content = $self->extract($archive);

    foreach my $resource ( $self->resources ) {
        say "     (moving) $resource->{from} -> $resource->{to}";
        my ( $from, $to ) = (
            $content->child( $resource->{from} )->absolute,
            $basedir->child( $resource->{to} )->absolute
        );
        
        $from->move(
            ( $from->is_dir() )
            ? $to->stringify
            : $to->touchpath->stringify
        );
    }

}
sub resources { @{ shift->[1]->{'resources'} } }

sub extract {
    my ( $self, $file ) = @_;

    my $ae = Archive::Extract->new( archive => $file->stringify );
    
    $ae->extract( to => $file->parent->stringify );

    return Path::Tiny::path( $ae->extract_path );
}

1;
