# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use VcsTools::Process ;

$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0 ;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict ;

my $res = openPipe 
  (
   command => 'ls',
   trace => $trace
  ) ;

print getError unless defined $res ;
print "not " unless grep(/Makefile.PL$/,@$res) == 1 ;
print "ok ",$idx++,"\n";

$res = pipeIn (command => 'bc',
               trace => $trace,
               input => "3+4+2\nquit\n"
              );
print getError unless defined $res ;
print "not " unless $res->[0] == 9 ;
print "ok ",$idx++,"\n";


$res = mySystem
  (
   command => 'echo "Dummy string printed on STDOUT"',
   trace => $trace,
  );

print getError unless defined $res ;
print "not " unless  $res == 1;
print "ok ",$idx++,"\n";

warn "Below is a normal error message (part of the test)\n";
$res = openPipe
  (
   command => 'ls dummy_dir',
   trace => $trace,
  );

print getError unless defined $res ;
print "not " if defined  $res;
print "ok ",$idx++,"\n";
