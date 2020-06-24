#!/usr/bin/env perl

use 5.016;

use Socket ':all';

socket my $s, PF_INET, SOCK_STREAM, IPPROTO_TCP  or die "socket: $!";

# my $host = 'search.cpan.org'; my $port = 80;
my $host = 'localhost'; my $port = 1234;
my $addr = gethostbyname $host;
my $sa = sockaddr_in($port, $addr);

# bind $s, sockaddr_in(1234, INADDR_ANY) or die "bind: $!";

connect $s, $sa or die  "connect: $!";
# $s->autoflush(1);

syswrite $s,"Testline";

while () {
    my $read = sysread($s, my $buf, 4096);
    if ($read) {
        say "Received $read bytes";
        use DDP;
        p $buf;
    }
    elsif(defined $read) {
        warn "EOF from server";
        last;
    }
    else {
        warn "Error from server: $!";
        last;
    }
}

__END__
# 1.
# $s->autoflush(1);
# print $s
#    "GET / HTTP/1.0\nHost: search.cpan.org\n\n";
# my @answer = <$s>;
# print @answer[0..9];

# 2.
# syswrite $s,
#     "GET / HTTP/1.0\nHost: search.cpan.org\n\n"
#     or die "send: $!";

# while () {
#     my $r = sysread $s, my $buf, 1024;
#     if ($r) { print $buf; }
#     elsif(defined $r) { last }
#     else { die "read failed: $!" }
# }

# 3.

send $s,
    "GET / HTTP/1.0\nHost: search.cpan.org\n\n",0
    or die "send: $!";

while () {
    my $r = recv $s, my $buf, 1024, 0;
    if (defined $r) {
        last unless length $buf;
        print $buf;
    }
    else { die "recv failed: $!" }
}

# recv $s, my $body, 256, 0;
# say $body;

# while (<$s>) {
#     say $_;
# }

# my @answer = <$s>;
# print @answer[0..9];
