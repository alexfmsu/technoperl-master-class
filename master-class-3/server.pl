#!/usr/bin/env perl

use 5.016;

$0 = 'testfork';

use Socket ':all';

socket my $s, AF_INET, SOCK_STREAM, IPPROTO_TCP or die "socket: $!";

setsockopt $s, SOL_SOCKET, SO_REUSEADDR, 1 or die "sso: $!";
# setsockopt $s, SOL_SOCKET, SO_REUSEPORT, 1 or die "sso: $!";

bind $s, sockaddr_in(1234, INADDR_ANY) or die "bind: $!";

# listen $s, SOMAXCONN or die "listen: $!";
listen $s, 0 or die "listen: $!";

my ($port, $addr) = sockaddr_in(getsockname($s));
say "Listening on ".inet_ntoa($addr).":".$port;

# $SIG{CHLD} = 'IGNORE';
# $SIG{CHLD} = 'DEFAULT';
$SIG{CHLD} = sub {

};

while() {

    while (my $peer = accept my $c, $s) {
        # got client socket $c
        my ($port, $addr) = sockaddr_in($peer);
        my $ip = inet_ntoa($addr);
        my $host = gethostbyaddr($addr, AF_INET);
        say "$$: Connected: $ip: $port ($host)";

        my $pid = fork();
        defined($pid) or die "$!";
        if ($pid) {
            say "$$: Forked cient worker ($pid)";
            close($c);
        }
        else {
            say "$$: client worker for $ip: $port ($host)";
            $0 = 'testfork - '."$ip:$port";

            # while (<$c>) { # read from client
            #     say "$$: got line '$_'";
            #     syswrite $c, $_;
            #     # print {$c} "processed: $_" or warn; # send it back
            # }

            while () {
                my $read = sysread($c, my $buf, 4096);
                if ($read) {
                    say "Received $read bytes";
                    use DDP;
                    p $buf;
                    sleep 1;
                    my $write = syswrite($c,$buf);
                    say "written: $write / $!";
                }
                elsif(defined $read) {
                    warn "EOF from client";
                    last;
                }
                else {
                    warn "Error from client: $!";
                    last;
                }
            }
            exit;
        }

    }

    # use Errno 'EINTR';
    # last unless $! == Errno::EINTR;

    last unless $!{EINTR};
}
warn "End: $!";

__END__
    defined (my $pid = fork()) or die "Can't fork: $!";
    if ($pid) {
        say "$$: Client connected from $ip:$port ($host), forked child $pid for process";
        close $c;
        next; # accept
    }
    else {
        say "$$: I'm child for $ip:$port";
        # use IO::Handle;
        $c->autoflush(1);
        $0 = 'testfork - '."$ip:$port";

        while (<$c>) { # read from client
            say "$$: got line '$_'";
            # syswrite $c, $_;
            print {$c} "processed: $_" or warn; # send it back
        }
        exit;
    }