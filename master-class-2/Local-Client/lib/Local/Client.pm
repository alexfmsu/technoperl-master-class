package Local::Client;

use 5.016;
use warnings;

our $VERSION = '0.01';

our %commands = (
	ls => sub {
		my $ctx = shift;
		die "Excess arguments" if $ctx->args;
		my $path = $ctx->path;
		if ($ctx->verbose > 1) {
			say "more debug";
		}
		say `ls -lA '$path'`;
	},
	cp => sub {
		die "Need 1..2 arguments" if @_ < 1 or @_ > 2;
		# my ($from,$to);
		# if (@_ == 2) {
		# 	$from = shift;
		# 	$to = "$path/".shift;
		# }
		# else {
		# 	$from = shift;
		# 	$to = "$path/";
		# }
		# say "copy '$from' => '$to'" if $verbose;
		# system("cp",$from,$to);
		# # say `cp '$from' '$to' 2>&1`;
	},
	mv => sub {
		die "Need 2 arguments" unless @_ == 2;
		# my ($from,$to) = @_;
		# say "rename '$from' => '$to'" if $verbose;

		# rename "$path/$from","$path/$to"
		# 	or warn "rename $from -> $to failed: $!\n";
	},
	rm => sub {
		die "Need 1 argument" unless @_ == 1;
		# my ($file) = @_;
		# say "remove '$file'" if $verbose;
		# unlink "$path/$file"
		# 	or warn "unlink $file failed: $!\n";
	},
);


sub execute {
	my $self = shift;
	my $context = shift;

	my ($cmd,@args) = split /\s+/, $_;
	unless (exists $commands{$cmd}) {
		say "Bad command '$cmd'";
		next;
	}
	$context->args(\@args);
	if ($context->verbose) {
		say "executing '$cmd' + (@args)";
	}
	eval {
		$commands{$cmd}($context);
	1} or do {
		warn $@;
	};

}

1;
