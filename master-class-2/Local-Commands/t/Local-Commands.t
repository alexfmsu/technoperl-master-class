# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Local-Commands.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 12;

BEGIN { use_ok('Local::Commands') };
BEGIN { use_ok('Local::Commands::Ls') };
BEGIN { use_ok('Local::Commands::Cp') };
BEGIN { use_ok('Local::Commands::Mv') };
BEGIN { use_ok('Local::Commands::Rm') };

can_ok 'Local::Commands', 'new', 'execute';
can_ok 'Local::Commands::Ls', 'new', 'execute';
can_ok 'Local::Commands::Cp', 'new', 'execute';
can_ok 'Local::Commands::Mv', 'new', 'execute';
can_ok 'Local::Commands::Rm', 'new', 'execute';

my $obj = Local::Commands::Ls->new(
	path => "."
);
my $res = $obj->execute;
my $should = `ls -lA .`;

is $res, $should, 'ls ok';
# diag $should;

eval {
	$obj->execute("123");
};
like $@, qr/^Excess arguments/;

done_testing();
