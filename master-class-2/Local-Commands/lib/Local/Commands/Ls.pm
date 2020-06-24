package Local::Commands::Ls;

use 5.016;
use warnings;
use parent 'Local::Commands::Base';


use Class::XSAcessor {
	accessors => [qw(verbose)],
}

# sub verbose {
# 	my $self = shift;
# 	if (@_) {
# 		$self->{verbose} = shift;
# 	}
# 	return $self->{verbose};
# }

sub execute {
	my $self = shift;

	die "Excess arguments" if @_;
	my $path = $self->{path};
	my $cmd = "ls -lA '$path'";
	if ($self->verbose > 1) {
		say "exec `$cmd`";
	}
	my $result = `$cmd`;
	return $result;
}

1;
