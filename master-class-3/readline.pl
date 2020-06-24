#!/usr/bin/env perl

use 5.016;

use DDP;
use Term::Readline;
BEGIN {
	Term::ReadLine::Gnu->import(qw(:keymap_type RL_STATE_INITIALIZED));
}


use Socket ':all';
socket my $s, PF_INET, SOCK_STREAM, IPPROTO_TCP  or die "socket: $!";
my $host = 'localhost'; my $port = 1234;
my $addr = gethostbyname $host;
my $sa = sockaddr_in($port, $addr);
connect $s, $sa or die  "connect: $!";
say "Connected: ".fileno($s);



my $prompt = "> ";
my $term = Term::ReadLine->new('Simple Perl calc');
my $OUT = $term->OUT || \*STDOUT;

say $term;
$term->CallbackHandlerInstall($prompt, sub {
	my $arg = shift;
	exit unless defined $arg;
	my $wr = syswrite($s,$arg);
	if (not $wr) {warn "Failed to write: $!";}
});

my %fileno_to_fd;
my $rvec;


$fileno_to_fd{ fileno(STDIN) } = \*STDIN;
vec($rvec,fileno(STDIN),1) = 1;

$fileno_to_fd{ fileno($s) } = $s;
vec($rvec,fileno($s),1) = 1;
# say unpack "b*", $rvec;

my $saved_point;
my $saved_line;

sub hide {
   $saved_point = $term->{point};
   $saved_line  = $term->{line_buffer};
   $term->rl_set_prompt ("");
   $term->{line_buffer} = "";
   $term->rl_redisplay;
}

END {
	if ($term) {
		hide()
	}
}

sub show {
   if (defined $saved_point) {
      $term->rl_set_prompt($prompt);
      $term->{line_buffer} = $saved_line;
      $term->{point}       = $saved_point;
      $term->redisplay;
   }
}

while () {
	my ($found) = select(my $rout = $rvec,undef,undef,1);
	# say $found;
	if ($found) {
		for (0..length($rout)*8-1) {
			if( vec($rout,$_,1) ) {
				# say "bit $_ is on";
				my $fd = $fileno_to_fd{ $_ }
					or die "Unknown fd $_";
				if ($fd == \*STDIN) {
					$term->rl_callback_read_char;
				}
				elsif ($fd == $s) {
					my $read = sysread($s, my $buf, 4096);
					if ($read) {
						hide();
						say "Received $read bytes";
						p $buf;
						show();
					}
					elsif(defined $read) {
						warn "EOF from server";
						exit;
					}
					else {
						warn "Error from server: $!";
						exit;
					}
				}
				else {
					warn "Do something else...";
				}
			}
		}
	}
}


# while () {
# 	warn "reading char";
# 	$term->rl_callback_read_char;
# }

__END__

while ( defined ($_ = $term->readline("> ")) ) {
	# my $res = eval($_);
	say "in >> $_";
	warn $@ if $@;
	# print $OUT $res, "\n" unless $@;
	# $term->addhistory($_) if /\S/;
}
