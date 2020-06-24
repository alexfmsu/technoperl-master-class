package Local::Client::Context;

use 5.016;
use warnings;

our $VERSION = '0.01';

use 5.016;
use warnings;

sub new {
	my $class = shift;
	my %args = ( verbose => 0, @_ );

	-e $args{path} or usage("Path `$args{path}' not exists");
	-d $args{path} or usage("Path `$args{path}' not a directory");
	$args{path} =~ s{/$}{}s;

	my $self = bless \%args, $class;
}

sub verbose {
	my $self = shift;
	if (@_) {
		$self->{verbose} = shift;
	}
	return $self->{verbose};
}

sub path {
	my $self = shift;
	if (@_) {
		$self->{path} = shift;
	}
	return $self->{path};
}

sub args {
	my $self = shift;
	if (@_) {
		my $args = shift;
		$self->{args} = $args if @$args;
	}
	return $self->{args};
}


1;
