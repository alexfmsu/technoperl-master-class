package Local::Commands::Base;

use 5.016;
use warnings;

sub new {
	my $class = shift;
	my %args = ( verbose => 0, @_ );
	my $self = bless \%args, $class;
}

sub execute {
	...
}

sub verbose {
	my $self = shift;
	if (@_) {
		$self->{verbose} = shift;
	}
	return $self->{verbose};
}

1;
