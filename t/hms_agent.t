# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use VcsTools::HmsAgent;
use Cwd;
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
   hmsHost => 'hptnofs',
   hmsDir =>'adir',
   hmsBase => 'abase',
   name => 'dummy.txt',
   trace => $trace,
   test => 1,
   workDir => cwd()
  );

print "ok ",$idx++,"\n";
my $res ;

$res = $h -> getHistory() ;
warn $res,"\n" if $trace;
print "not " unless $res eq 'fhist -hhptnofs /abase/adir/dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> checkOut(revision => '1.51', lock => 0) ;
warn $res,"\n" if $trace;
print "not " unless $res eq 'fco -hhptnofs -r1.51 /abase/adir/dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> checkOut(revision => '1.51.1.1', lock => 1) ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fco -l -hhptnofs -r1.51.1.1 /abase/adir/dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> getContent(revision => '1.52') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fco -p -r1.52 -hhptnofs /abase/adir/dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> checkArchive(revision => '1.51.1.1') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fll -N -hhptnofs /abase/adir/dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> changeLock(lock => 1,revision => '1.51.1.1' ) ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil -l -hhptnofs -r1.51.1.1 /abase/adir/dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> changeLock(lock => 0,revision => '1.51.1.1' ) ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil -u -hhptnofs -r1.51.1.1 /abase/adir/dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> archiveLog('log' => "new dummy\nhistory\n",
                     state => 'Dummy', revision => '1.52') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil  -hhptnofs -sDummy:1.52 /abase/adir/dummy.txt 2>&1
futil  -hhptnofs -m1.52:\'new dummy
history
\' /abase/adir/dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> showDiff(rev1 => '1.41') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fdiff -hhptnofs -r1.41 /abase/adir/dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> showDiff(rev1 => '1.41', rev2 => '1.43') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fdiff -hhptnofs -r1.41 -r1.43 /abase/adir/dummy.txt 2>&1';
print "ok ",$idx++,"\n";

$res = $h -> checkIn(revision => '1.52', 
              'log' => "dummy log\nof a file\n") ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq "fci -hhptnofs -u -r1.52 -m'dummy log\nof a file\n' /abase/adir/dummy.txt 2>&1";
print "ok ",$idx++,"\n";

$res = $h -> create();
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil -M -hhptnofs /abase/adir
fci -auto -hhptnofs -u /abase/adir/dummy.txt';
print "ok ",$idx++,"\n";

$res = $h -> mkHmsDir();
warn $res,"\n" if $trace;
print "not " 
  unless $res eq "futil -M -hhptnofs /abase/adir\n";
print "ok ",$idx++,"\n";

$res = $h -> mkHmsDir(hmsDir => 'a/dummy//dir/');
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil -M -hhptnofs /abase/a
futil -M -hhptnofs /abase/a/dummy
futil -M -hhptnofs /abase/a/dummy/dir
';
print "ok ",$idx++,"\n";

$res = $h -> mkHmsDir(hmsHost => 'moon', hmsBase => 'alpha',
                      hmsDir => 'a/dummy//dir/');
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'futil -M -hmoon /alpha/a
futil -M -hmoon /alpha/a/dummy
futil -M -hmoon /alpha/a/dummy/dir
';
print "ok ",$idx++,"\n";

$res = $h -> list() ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fll -RN -hhptnofs /abase/adir';
print "ok ",$idx++,"\n";

$res = $h -> list(hmsHost => 'moon', hmsBase => 'alpha',
                  hmsDir => 'a/dummy//dir/') ;
warn $res,"\n" if $trace;
print "not " 
  unless $res eq 'fll -RN -hmoon /alpha/a/dummy//dir/';
print "ok ",$idx++,"\n";
