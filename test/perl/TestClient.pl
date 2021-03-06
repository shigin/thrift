#!/usr/bin/perl

require 5.6.0;
use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);

use lib '../../lib/perl/lib';
use lib '../gen-perl';

use Thrift;
use Thrift::BinaryProtocol;
use Thrift::Socket;
use Thrift::BufferedTransport;

use ThriftTest;
use ThriftTest::Types;

$|++;

my $host = 'localhost';
my $port = 9090;


my $socket = new Thrift::Socket($host, $port);

my $bufferedSocket = new Thrift::BufferedTransport($socket, 1024, 1024);
my $transport = $bufferedSocket;
my $protocol = new Thrift::BinaryProtocol($transport);
my $testClient = new ThriftTestClient($protocol);

eval{
$transport->open();
}; if($@){
    die(Dumper($@));
}
my $start = gettimeofday();

#
# VOID TEST
#
print("testVoid()");
$testClient->testVoid();
print(" = void\n");

#
# STRING TEST
#
print("testString(\"Test\")");
my $s = $testClient->testString("Test");
print(" = \"$s\"\n");

#
# BYTE TEST
#
print("testByte(1)");
my $u8 = $testClient->testByte(1);
print(" = $u8\n");

#
# I32 TEST
#
print("testI32(-1)");
my $i32 = $testClient->testI32(-1);
print(" = $i32\n");

#
#I64 TEST
#
print("testI64(-34359738368)");
my $i64 = $testClient->testI64(-34359738368);
print(" = $i64\n");

#
# DOUBLE TEST
#
print("testDouble(-852.234234234)");
my $dub = $testClient->testDouble(-852.234234234);
print(" = $dub\n");

#
# STRUCT TEST
#
print("testStruct({\"Zero\", 1, -3, -5})");
my $out = new ThriftTest::Xtruct();
$out->string_thing("Zero");
$out->byte_thing(1);
$out->i32_thing(-3);
$out->i64_thing(-5);
my $in = $testClient->testStruct($out);
print(" = {\"".$in->string_thing."\", ".
        $in->byte_thing.", ".
        $in->i32_thing.", ".
        $in->i64_thing."}\n");

#
# NESTED STRUCT TEST
#
print("testNest({1, {\"Zero\", 1, -3, -5}, 5}");
my $out2 = new ThriftTest::Xtruct2();
$out2->byte_thing(1);
$out2->struct_thing($out);
$out2->i32_thing(5);
my $in2 = $testClient->testNest($out2);
$in = $in2->struct_thing;
print(" = {".$in2->byte_thing.", {\"".
      $in->string_thing."\", ".
      $in->byte_thing.", ".
      $in->i32_thing.", ".
      $in->i64_thing."}, ".
      $in2->i32_thing."}\n");

#
# MAP TEST
#
my $mapout = {};
for (my $i = 0; $i < 5; ++$i) {
  $mapout->{$i} = $i-10;
}
print("testMap({");
my $first = 1;
while( my($key,$val) = each %$mapout) {
    if ($first) {
        $first = 0;
    } else {
        print(", ");
    }
    print("$key => $val");
}
print("})");


my $mapin = $testClient->testMap($mapout);
print(" = {");

$first = 1;
while( my($key,$val) = each %$mapin){
    if ($first) {
        $first = 0;
    } else {
        print(", ");
    }
    print("$key => $val");
}
print("}\n");

#
# SET TEST
#
my $setout = [];
for (my $i = -2; $i < 3; ++$i) {
    push(@$setout, $i);
}

print("testSet({".join(",",@$setout)."})");

my $setin = $testClient->testSet($setout);

print(" = {".join(",",@$setout)."}\n");

#
# LIST TEST
#
my $listout = [];
for (my $i = -2; $i < 3; ++$i) {
    push(@$listout, $i);
}

print("testList({".join(",",@$listout)."})");

my $listin = $testClient->testList($listout);

print(" = {".join(",",@$listin)."}\n");

#
# ENUM TEST
#
print("testEnum(ONE)");
my $ret = $testClient->testEnum(Numberz::ONE);
print(" = $ret\n");

print("testEnum(TWO)");
$ret = $testClient->testEnum(Numberz::TWO);
print(" = $ret\n");

print("testEnum(THREE)");
$ret = $testClient->testEnum(Numberz::THREE);
print(" = $ret\n");

print("testEnum(FIVE)");
$ret = $testClient->testEnum(Numberz::FIVE);
print(" = $ret\n");

print("testEnum(EIGHT)");
$ret = $testClient->testEnum(Numberz::EIGHT);
print(" = $ret\n");

#
# TYPEDEF TEST
#
print("testTypedef(309858235082523)");
my $uid = $testClient->testTypedef(309858235082523);
print(" = $uid\n");

#
# NESTED MAP TEST
#
print("testMapMap(1)");
my $mm = $testClient->testMapMap(1);
print(" = {");
while( my ($key,$val) = each %$mm) {
    print("$key => {");
    while( my($k2,$v2) = each %$val) {
        print("$k2 => $v2, ");
    }
    print("}, ");
}
print("}\n");

#
# INSANITY TEST
#
my $insane = new ThriftTest::Insanity();
$insane->{userMap}->{Numberz::FIVE} = 5000;
my $truck = new ThriftTest::Xtruct();
$truck->string_thing("Truck");
$truck->byte_thing(8);
$truck->i32_thing(8);
$truck->i64_thing(8);
push(@{$insane->{xtructs}}, $truck);

print("testInsanity()");
my $whoa = $testClient->testInsanity($insane);
print(" = {");
while( my ($key,$val) = each %$whoa) {
    print("$key => {");
    while( my($k2,$v2) = each %$val) {
        print("$k2 => {");
        my $userMap = $v2->{userMap};
        print("{");
        if (ref($userMap) eq "HASH") {
            while( my($k3,$v3) = each %$userMap) {
                print("$k3 => $v3, ");
            }
        }
        print("}, ");

        my $xtructs = $v2->{xtructs};
        print("{");
        if (ref($xtructs) eq "ARRAY") {
            foreach my $x (@$xtructs) {
                print("{\"".$x->{string_thing}."\", ".
                      $x->{byte_thing}.", ".$x->{i32_thing}.", ".$x->{i64_thing}."}, ");
            }
        }
        print("}");

        print("}, ");
    }
    print("}, ");
}
print("}\n");

#
# EXCEPTION TEST
#
print("testException('Xception')");
eval {
    $testClient->testException('Xception');
    print("  void\nFAILURE\n");
}; if($@ && $@->UNIVERSAL::isa('ThriftTest::Xception')) {
    print(' caught xception '.$@->{errorCode}.': '.$@->{message}."\n");
}


#
# Normal tests done.
#
my $stop = gettimeofday();
my $elp  = sprintf("%d",1000*($stop - $start), 0);
print("Total time: $elp ms\n");

#
# Extraneous "I don't trust PHP to pack/unpack integer" tests
#

# Max I32
my $num = 2**30 + 2**30 - 1;
my $num2 = $testClient->testI32($num);
if ($num != $num2) {
    print "Missed max32 $num = $num2\n";
}

# Min I32
$num = 0 - 2**31;
$num2 = $testClient->testI32($num);
if ($num != $num2) {
    print "Missed min32 $num = $num2\n";
}

# Max Number I can get out of my perl
$num = 2**40;
$num2 = $testClient->testI64($num);
if ($num != $num2) {
    print "Missed max64 $num = $num2\n";
}

# Max Number I can get out of my perl
$num = 0 - 2**40;
$num2 = $testClient->testI64($num);
if ($num != $num2) {
    print "Missed min64 $num = $num2\n";
}

$transport->close();



