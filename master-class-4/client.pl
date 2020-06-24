#!/usr/bin/env perl

# use subs 'say';
use strict;
use feature 'switch';
no warnings 'experimental';
use Socket ':all';
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::ReadLine::Gnu;
use DDP;

sub say {
	# warn "my say";
	my $line = "@_";
	$line =~ s{\n*$}{\n};
	AnyEvent::ReadLine::Gnu->print($line);
}

my $cv = AE::cv;

# if (@ARGV != 1) { die "Usage:\n\t$0 file\n"; }
# my ($file) = @ARGV;
# my $size = -s $file;
# defined $size or die "File '$file': $!\n";
# say "Uploading file '$file' of size $size";

my $BUFSIZE = 2**19;

my $rl;
END {
	if ($rl) { $rl->hide; }
}

tcp_connect 0, 1234, sub {
	my $fh = shift
		or return warn "Connect failed: $!";

	
	my $h; $h = AnyEvent::Handle->new(
		fh => $fh,
		on_error => sub {
			warn "handle closed: @_";
			# p $h;
			$h->destroy;
			$cv->send;
		},
		timeout => 30,
	);

	my $command = sub {
		my $cmd = shift;
		AnyEvent::ReadLine::Gnu->hide;

		$h->push_write("$cmd\n");
		$h->push_read(line => sub {
			if ($_[1] =~ /^OK\s+(\d+)/) {
				$h->unshift_read(chunk => $1, sub {
					say $_[1];
					AnyEvent::ReadLine::Gnu->show;
				});
			}
			else {
				say $_[1];
				AnyEvent::ReadLine::Gnu->show;
			}
		});

	};

	my $put = sub {
		my $file = shift;
		my $size = -s $file;
		defined $size or return say("File '$file': $!");
		AnyEvent::ReadLine::Gnu->hide;
		say "Uploading file '$file' of size $size";

		my $left = $size;
		my ($name) = $file =~ m{(?:^|/)([^/]+)$};
		$h->push_write("put $size $name\n");
		$h->push_read(line => sub {
			if ($_[1] =~ /^OK\s+(\d+)/) {
				$h->unshift_read(chunk => $1, sub {
					say $_[1];
				});
			}
			else {
				say $_[1];
			}
		});
		open my $f, '<:raw', $file or $cv->croak("Failed to open file '$file': $!");
		my $rh;$rh = AnyEvent::Handle->new(
			fh => $f,
			on_error => sub {
				shift;
				warn "file error: @_";
				$rh->destroy;
			},
			max_read_size => $BUFSIZE,
			read_size     => $BUFSIZE,
			# on_read => sub {
			# 	my $wr = delete $_[0]{rbuf};
			# 	# p $rh;
			# 	$left -= length $wr;
			# 	$h->push_write($wr);
			# 	say "write buffer ".length $h->{wbuf};
			# },
		);

		my $do;$do = sub {
			if ($left > 0) {
				$rh->push_read(chunk => $left > $BUFSIZE ? $BUFSIZE : $left, sub {
					my $wr = $_[1];
					$left -= length $wr;
					$h->push_write($wr);
					if ($h->{wbuf}) {
						say "write buffer ".length $h->{wbuf};
						$h->on_drain(sub {
							# warn "drained";
							$h->on_drain(undef);
							$do->();
						});
					}
					else {
						# say "send successfully ".length $wr;
						$do->();
					}
				});
			}
			else {
				warn "finish";
				$rh->destroy;
				AnyEvent::ReadLine::Gnu->show;

				# $h->on_drain(sub {
				# 	$h->destroy;
				# 	$cv->send;
				# });
			}
		};$do->();

	};

	$rl = AnyEvent::ReadLine::Gnu->new(
		prompt => "xxx> ",
		on_line => sub {
			given (shift) {
				when (undef) { # Ctrl + D
					$cv->send;
				}
				when(/put \s+ (.+?)\s*$/x) {
					$put->($1);
				}
				when(/^(ls)$/x) {
					$command->($1);
				}
				default {
					say "wrong command: $_";
				}
			}
		},
	);

	# my $length = length $data;
	
	# $h->push_write("put $length\n$data");
	# p $h->{wbuf};

	# $h->push_write("ls\n");
	# p $h->{wbuf};

	# $h->on_drain(sub {
	# 	warn "drain";
	# 	p $h;
	# 	# $h->destroy;
	# });



}, sub {
	my $fh = shift;
	# setsockopt($fh, SOL_SOCKET, SO_SNDBUF, 1024) or warn "setsockopt failed: $!";
	# warn "prepare: @_";
	1;
};

$cv->recv;
