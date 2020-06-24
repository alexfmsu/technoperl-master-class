#!/usr/bin/env perl

use 5.016;
use DDP;
use Getopt::Long;
use Term::ReadLine;
BEGIN {
    import Term::ReadLine::Gnu qw(RL_PROMPT_START_IGNORE RL_PROMPT_END_IGNORE);
}
sub usage(;$) {
	warn $_[0] if @_;
	warn <<END;
Usage:
	$0 [-h] [-v] /path/to/somewhere

	-h | --help     - print usage and exit
	-v | --verbose  - be verbose
END
	exit 1;
}

my $verbose;
GetOptions(
	'h|help' => sub { usage() },
	'v|verbose' => \$verbose,
) or usage;

@ARGV == 1 or usage;
my $path = shift @ARGV;
-e $path or usage("Path `$path' not exists");
-d $path or usage("Path `$path' not a directory");
$path =~ s{/$}{}s;

my $CLR = RL_PROMPT_START_IGNORE."\e[0m".RL_PROMPT_END_IGNORE;
our $prompt = "$CLR> ";

$|++;
our $term = Term::ReadLine->new('Client');
$term->ReadHistory("$ENV{HOME}/.sphere_hw1");
my $out = $term->OUT || \*STDOUT;
$term->Attribs->{completion_entry_function} =
	$term->Attribs->{list_completion_function};
$term->Attribs->{completion_word} = [qw(
	ls cp mv rm
)];

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

while ( defined( $_ = $term->readline($prompt) )) {
	if (substr($_,0,1) eq '!' ) {
		substr($_,0,1,'');
		say "executing shell command '$_'" if $verbose;
		system($_);
		next;
	}
	my ($cmd,@args) = split /\s+/, $_;
	unless (exists $commands{$cmd}) {
		say "Bad command '$cmd'";
		next;
	}
	if ($verbose) {
		say "executing '$cmd' + (@args)";
	}
	eval {
		$commands{$cmd}(@args);
	1} or do {
		warn $@;
	};
} continue {
	$term->rl_set_prompt("");
	$term->{line_buffer} = "";
	$term->{point}       = 0;
	$term->redisplay;
}

END {
	if ($term) {
		$term->WriteHistory("$ENV{HOME}/.sphere_hw1")
			or warn "WriteHistory failed: $!";
		$term->rl_set_prompt("");
		$term->{line_buffer} = "";
		$term->rl_redisplay;
	}
}