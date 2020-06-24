#!/usr/bin/env perl

use 5.016;

use Socket ':all';

socket my $s, AF_INET, SOCK_DGRAM, IPPROTO_UDP or die "socket: $!";

my $host = 'localhost'; my $port = 1234;
my $addr = gethostbyname $host;
my $sa = sockaddr_in($port, $addr);

# use DDP;
# say inet_ntoa substr($sa,0,4);

send($s, "test direct message", 0, $sa);

# connect $s, $sa;
# send($s, "test 'connected' message", 0);


while (my $peer = recv( $s, my $msg, 8*2048, 0 )) {
    my ($port, $addr) = sockaddr_in($peer);
    my $ip = inet_ntoa($addr);
    say "Message $msg from $ip:$port";
	send($s, "reply: $msg", 0, $peer);

    # sleep 1;
}

# recv($s, my $msg, 2048, 0 );
# say $msg;