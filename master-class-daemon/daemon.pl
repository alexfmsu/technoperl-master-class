use 5.016;
use Fcntl qw(O_CREAT  O_EXCL  O_RDWR LOCK_EX LOCK_NB);
use Getopt::Long;

my $do_stop;
GetOptions(
	's|signal=s' => sub {
		if ($_[1] eq 'stop') {
			$do_stop = 1;
		}
		else {
			die "Bad signal";
		}
	},
) or die;

my $pfile = "/tmp/daemon.pid";
my $pfd;
my $do_delete;
END {
	if ($pfd and $do_delete) {
		unlink $pfile;
	}
}
OPEN: {
	my $flags = -e $pfile ? O_RDWR :
		(O_CREAT | O_EXCL | O_RDWR);
	my $errno = !-e $pfile ? 'ENOENT' : 'EEXIST';
	unless (sysopen($pfd, $pfile, $flags)) {
		redo OPEN if $!{$errno};
		die "open $pfile: $!";
	}
}
if (flock($pfd, LOCK_EX | LOCK_NB)) {
	say "$$: Locked";
	if ($do_stop) {
		$do_delete = 1;
		say "Not running";
		exit;
	}
} else {
	say "$$: Already locked";
	chomp(my $pid = <$pfd>);
	if ($do_stop) {
		kill TERM => $pid;
		exit;
	} else {
		die "Already running (pid $pid)\n";
	}
}

open my $log, ">>", "daemon.log" or die "daemon.log open failed: $!";
my $pid = fork and exit;

	seek $pfd, 0, 0;
	truncate($pfd,0);
	syswrite $pfd, "$$\n";
	$do_delete = 1;

say "$$: written pid";

defined $pid or die "Failed to spawn: $!";
use POSIX qw(setsid strftime);
setsid();

#close STDIN; open STDIN, '<', '/dev/null';
open STDIN, '<', '/dev/null' or die "Failed to reopen STDIN";

{
	package MyOut;
	use base qw(Tie::Handle);
	sub TIEHANDLE {
		my $class = shift;
		my $cb = shift;
		my $self = bless {cb => $cb}, $class;
		return $self;
	}
	sub PRINT {
		my $self = shift;
		$self->{cb}->(@_);
	}
}

open STDOUT, '>&', $log or die "Failed to dup STDOUT: $!";
open STDERR, '>&', $log or die "Failed to dup STDOUT: $!";
tie *STDOUT, 'MyOut', sub {
	syswrite $log, sprintf "[%s] [%d] [O] %s\n",
		strftime("%Y-%m-%d %H:%M:%S",localtime()), $$, "@_";
};
tie *STDERR, 'MyOut', sub {
	syswrite $log, sprintf "[%s] [%d] [E] %s\n",
		strftime("%Y-%m-%d %H:%M:%S",localtime()), $$, "@_";
};
warn "test";
$0 = "daemon - start";

my $work = 1;
$SIG{INT} = $SIG{TERM} = sub {
	$0 = "daemon - stopping";
	say "$$: Stopping ($work)";
	unless ($work) {
		say "$$: Forced exit\n";
		exit;
	}
	else { $work = 0 }
};
$SIG{HUP} = sub {
	if (open my $newlog, ">>", "daemon.log") {
		$log = $newlog;
		#open STDOUT, '>&', $log or die "Failed to dup STDOUT: $!";
		open STDERR, '>&', $log or die "Failed to dup STDOUT: $!";
	} else {
		warn "daemon.log open failed: $!";
	}
};

use Time::HiRes qw(time sleep);

while ($work) {
	my $to_sleep = time + 1;
	while () {
		my $remaining = $to_sleep - time;
		last if $remaining <= 0;
		say "Do work $remaining";
		select undef,undef,undef,$remaining;
	}
}