package Local::Commands;

use 5.016;
use warnings;

use Local::Commands::Ls;
use Local::Commands::Cp;
use Local::Commands::Rm;
use Local::Commands::Mv;

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my %args = @_;
	-e $args{path} or usage("Path `$args{path}' not exists");
	-d $args{path} or usage("Path `$args{path}' not a directory");
	$args{path} =~ s{/$}{}s;
	my $self = bless {
		%args,
		commands => {
			ls => Local::Commands::Ls->new( %args ),
			cp => Local::Commands::Cp->new( %args ),
			rm => Local::Commands::Rm->new( %args ),
			mv => Local::Commands::Mv->new( %args ),
		}
	}, $class;
	return $self;
}

sub verbose {
	my $self = shift;
	if (@_) {
		$self->{verbose} = shift;
	}
	return $self->{verbose};
}

sub execute {
	my $self = shift;
	my $arg = shift;
	my ($cmd,@args) = split /\s+/, $arg;

	unless (exists $self->{commands}{$cmd}) {
		say "Bad command '$cmd'";
	}
	if ($self->verbose) {
		say "executing '$cmd' + (@args)";
	}
	if ($self->verbose > 1) {
		warn "call to object ", $self->{commands}{$cmd};
	}
	eval {
		say $self->{commands}{$cmd}->execute(@args);
	1} or do {
		warn $@;
	};

}


1;
__END__

our %commands = (
	ls => sub {
		die "Excess arguments" if @_;
		say `ls -lA '$path'`;
	},
	cp => sub {
		die "Need 1..2 arguments" if @_ < 1 or @_ > 2;
		my ($from,$to);
		if (@_ == 2) {
			$from = shift;
			$to = "$path/".shift;
		}
		else {
			$from = shift;
			$to = "$path/";
		}
		say "copy '$from' => '$to'" if $verbose;
		system("cp",$from,$to);
		# say `cp '$from' '$to' 2>&1`;
	},
	mv => sub {
		die "Need 2 arguments" unless @_ == 2;
		my ($from,$to) = @_;
		say "rename '$from' => '$to'" if $verbose;

		rename "$path/$from","$path/$to"
			or warn "rename $from -> $to failed: $!\n";
	},
	rm => sub {
		die "Need 1 argument" unless @_ == 1;
		my ($file) = @_;
		say "remove '$file'" if $verbose;
		unlink "$path/$file"
			or warn "unlink $file failed: $!\n";
	},
);