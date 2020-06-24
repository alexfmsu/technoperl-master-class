#!/usr/bin/env perl

use 5.016;
use AnyEvent;
use DDP;
use EV;

sub parallel {
	my $name = shift;
	my $cb = shift;

	my $mycv = AE::cv;
	$mycv->begin;
	for my $n (1..10) {
		$mycv->begin;
		my $t;$t = AE::timer rand(), 0, sub {
			undef $t;
			warn "$name timer $n";
			$mycv->end;
		};
	}
	$mycv->cb(sub {
		warn "$name cv was sent";
		$cb->();
	});
	$mycv->end;

}

my $cv = AE::cv {
	warn "done";
	EV::unloop();
};

my $t = AE::timer 1,1,sub{};

$cv->begin;
parallel("ab",sub{
	$cv->end;
});

$cv->begin;
parallel("xy",sub{
	$cv->end;
});


# $cv->recv;
my $zero = AE::timer 0,0, sub { warn "zero"; };
warn "enter loop";
EV::loop();
warn "done";
