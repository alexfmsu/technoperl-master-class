#!/usr/bin/env perl

use 5.016;
use DDP;
use Getopt::Long qw(:config no_ignore_case bundling);
use Term::ReadLine;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Local::Commands;


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
	'v|verbose+' => \$verbose,
) or usage;

@ARGV == 1 or usage;
my $path = shift @ARGV;

my $cmd = Local::Commands->new(
	path => $path,
	verbose => $verbose,
);

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



while ( defined( $_ = $term->readline($prompt) )) {
	if (substr($_,0,1) eq '!' ) {
		substr($_,0,1,'');
		say "executing shell command '$_'" if $verbose;
		system($_);
		next;
	}
	$cmd->execute( $_ );
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