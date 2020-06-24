#!/usr/bin/env perl

use 5.016;
use AnyEvent;
use Socket ':all';
use AnyEvent::Socket;
use AnyEvent::Handle;
use DDP;
use EV;

my $BUFSIZE = 2**19;

tcp_server 0,1234, sub {
	my $fh = shift;
	# setsockopt($fh, SOL_SOCKET, SO_RCVBUF, 1024) or warn "setsockopt failed: $!";
	warn "Client connected: @_";
	# my $rw; $rw = AE::io $fh, 0, sub {
	# 	$rw;
	# 	my $r = sysread($fh, my $buf, 4096);
	# 	if ($r) {
	# 		warn "read: $r, $buf";
	# 	}
	# 	elsif($!{EAGAIN}) { return }
	# 	else {
	# 		warn "Client disconnected";
	# 		close $fh;
	# 		undef $rw;
	# 	}
	# };
	my $t;$t = AE::timer 0.1, 0, sub {
		undef $t;

		my $h; $h = AnyEvent::Handle->new(
			fh => $fh,
			on_error => sub {
				warn "handle closed: @_";
				p $h;
				$h->destroy;
			},

			max_read_size => $BUFSIZE,
			read_size => $BUFSIZE,

			timeout => 600,
			# on_read => sub {
			# 	my $h = shift;
			# 	warn "on read + '$h->{rbuf}' [@{ $h->{_queue} }]";
			# 	# my $read = delete $h->{rbuf};

			# 	# if (length $h->{rbuf} > 12) {
			# 	# 	my $read = substr($h->{rbuf},0,12,'');
			# 	# 	say "read: '$read'";
			# 	# }
			# 	warn "push read";
			# 	$h->push_read(chunk => 20, sub {
			# 		my (undef,$read) = @_;
			# 		say "read '$read'";
			# 	});
			# 	warn "have queue: [@{ $h->{_queue} }]";
			# },
		);

		my $reply = sub {
			if (defined $_[0]) {
				$h->push_write("OK ".(length($_[0])+1)."\n".$_[0]."\n");
			}
			else {
				my $err = $_[1];
				$err =~ s{\n}{ }sg;
				$h->push_write("ERR $err\n");
			}
		};

		# $h->push_read( line => qr/;/, sub {
		# 	warn "read + '$h->{rbuf}' [@{ $h->{_queue} }]";
		# 	my (undef, $word) = @_;
		# 	say "read word 1 '$word'";
		# } );
		# $h->push_read( line => qr/;/, sub {
		# 	warn "read + '$h->{rbuf}' [@{ $h->{_queue} }]";
		# 	my (undef, $word) = @_;
		# 	say "read word 2 '$word'";
		# } );
		# $h->push_read( line => qr/;/, sub {
		# 	warn "read + '$h->{rbuf}' [@{ $h->{_queue} }]";
		# 	my (undef, $word) = @_;
		# 	say "read word 3 '$word'";
		# } );
		# $h->push_read( line => sub {
		# 	warn "read + '$h->{rbuf}' [@{ $h->{_queue} }]";
		# 	my (undef, $left) = @_;
		# 	say "read leftover '$left'";
		# } );


		# my $reader;$reader = sub {
		# 	$h->push_read( line => qr/(;|\015?\012)/, sub {
		# 		$reader->();
		# 		warn "on read + '$h->{rbuf}' [@{ $h->{_queue} }]";
		# 		shift;
		# 		my $line = shift;

		# 		p @_;
		# 	} );
		# };$reader->();

		my $reader;$reader = sub {
			$h->push_read( line => sub {
				$reader->();

				# warn "on read + '$h->{rbuf}' [@{ $h->{_queue} }]";
				shift;
				my $line = shift;
				p $line;
				if ($line =~ /^put\s+(\d+)\s+(.+)$/) {
					my ($size,$file) = ($1,$2);
					say "command put on $size bytes for $file";
					my $left = $size;
					open my $fh, '>:raw', "store/$file";
						# or do {  };

					my $body;$body = sub {
						$h->unshift_read( chunk => $left > $BUFSIZE ? $BUFSIZE : $left, sub {
							my $rd = $_[1];
							$left -= length $rd;
							warn sprintf "read %d, left %s\n",length($rd),$left;
							syswrite($fh,$rd);
							if ($left == 0) {
								undef $body;
								close $fh;
								$reply->("File saved");
							}
							else {
								$body->();
							}
						} );
					};$body->();

					# ### WRONG
					# my $queue = delete $h->{_queue}; # DO NOT DO SO
					# my $left = $size;
					# $h->on_read(sub {
					# 	my $rd;
					# 	if (length $h->{rbuf} < $left) {
					# 		$rd = delete $h->{rbuf};
					# 		$left -= length $rd;
					# 		warn sprintf "read %d of %s\n",length($rd),$left;
					# 	}
					# 	else {
					# 		$rd = substr($h->{rbuf},0,$left,'');
					# 		warn "received all";
					# 		$h->on_read(undef);
					# 		$h->{_queue} = $queue;
					# 	}
					# });
					# ### WRONG

					# $h->unshift_read( chunk => $1, sub {
					# 	shift;
					# 	# warn "in chunk: '$h->{rbuf}' [@{ $h->{_queue} }]";
					# 	say "body for put: $_[0]";
					# 	# p @_;
					# } );
					# warn "after unshift: '$h->{rbuf}' [@{ $h->{_queue} }]";
				}
				elsif ($line eq '') {
					# skip
				}
				else {
					say "command $line";
					given($line) {
						when ('ls') {
							my $out = `ls -lA store`;
							$reply->($out);
							# $h->push_write("OK ".(length($out)+1)."\n".$out."\n");
						}
						default {
							$reply->("Unknown command");
							# $h->push_write("ERR Unknown command\n");
						}
					}
				}

			} );
		};$reader->();
	};
},
sub {
	my ($fh,$host,$port) = @_;
	say "Listening on $host:$port";
	1024;
};


EV::loop();
