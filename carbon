package Carbon;

use common::sense;
use HTTP::Tiny;
use Data::Dmp;

sub new
{	
	return bless [ Carbon::Enviroment->new ], shift;
}


sub run
{
	my ( $self ) = shift;
	
	foreach my $instruction ( $self->[0]->instructions )
	{		
		my ( $action ) = keys %$instruction;
		
		if ( lc( $instruction->{ $action }->{'target'} ) eq $self->[0]->os )
		{
			my $details = $instruction->{ $action };
			dd $details;
		}
		
	}
}


# CLI
# ---------------------------------------

(sub{
	
	Carbon->new()->run();
	
})->() if not caller();

# #######################################
# # CARBON::ENVIROMENT
# #######################################
package Carbon::Enviroment;

use YAML::Tiny;

sub new {
	bless [
		( -e $0.'.yml' ) ? YAML::Tiny->read( $0.'.yml' )->[0] : []
	], shift;
}

sub instructions { @{ shift->[0] } }
sub os { "$^O"; }

# #######################################
# # CARBON::FETCH
# #######################################
package Carbon::Fetch



1;