# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use Cwd;
use VcsTools::HmsAgent;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

my $trace = shift || 0 ;


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package main ;

my $h = new VcsTools::HmsAgent 
  (
   name => 'dummy.txt',
   trace => $trace,
   test => 1,
   workDir => cwd()
  );

print "ok ",$idx++,"\n";
my $res ;

$res = $h -> getHistory() ;
warn $res,"\n" if $trace;
print "not " unless $res eq 'fhist  dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> checkOut(revision => '1.51', lock => 0) ;
warn $res,"\n" if $trace;
print "not " unless $res eq 'fco  -r1.51 dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> checkOut(revision => '1.51.1.1', lock => 1) ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fco -l  -r1.51.1.1 dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> getContent(revision => '1.52') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fco -p -r1.52  dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> checkArchive(revision => '1.51.1.1') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fll -N  dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> changeLock(lock => 1,revision => '1.51.1.1' ) ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil -l  -r1.51.1.1 dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> changeLock(lock => 0,revision => '1.51.1.1' ) ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil -u  -r1.51.1.1 dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> archiveLog('log' => "new dummy\nhistory\n",
                     state => 'Dummy', revision => '1.52') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil   -sDummy:1.52 dummy.txt 2>&1
futil   -m1.52:\'new dummy
history
\' dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> showDiff(rev1 => '1.41') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fdiff  -r1.41 dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> showDiff(rev1 => '1.41', rev2 => '1.43') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fdiff  -r1.41 -r1.43 dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> checkIn(revision => '1.52', 
              'log' => "dummy log\nof a file\n") ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq "fci  -u -r1.52 -m'dummy log\nof a file\n' dummy.txt 2>&1";
print "ok ",$idx++,"\n";

$res = $h -> create();
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fci -auto  -u dummy.txt';
print "ok ",$idx++,"\n";

