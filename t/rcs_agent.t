# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $skipIt ;
BEGIN 
  { 
    $| = 1; 
    if (system('rcs') > 512)
      {
        warn "You don't have the RCS VCS system\n",
        "Skipping most of this test\n";
        print "1..1\n";
        $skipIt = 1;
      }
    else
      {
        print "1..15\n"; 
        $skipIt = 0 ;
      }
  }

END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use VcsTools::RcsAgent;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

my $trace = shift || 0 ;


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package main ;

my $file = 'dummy.txt';

warn "heavy cleanup\n";
mkdir ('RCS', 0755) or die "Can't mkdir RCS:$!" unless -d 'RCS' ;
unlink ("RCS/$file,v") or die "Can't unlink RCS/$file,v:$!" 
  if -e "RCS/$file,v" ;
unlink ($file) or die "Can't unlink $file:$!" if -e $file ;

print "ok ",$idx++,"\n";

my $h = new VcsTools::RcsAgent 
  (
   name => $file,
   trace => $trace,
   workDir => $ENV{'PWD'}
  );

print "ok ",$idx++,"\n";
my $res ;

warn "normal error below\n";
$res = $h -> checkArchive() ;
print "not " if defined $res;
print "ok ",$idx++,"\n";

open(FILE,">$file") || die "open file failed\n";
print FILE "# \$Revision\$\nDummy text\n";
close FILE ;

$res = $h -> create();
warn "@$res\n" if $trace;
print "not " unless defined $res;
print "not " if -w $file;
print "ok ",$idx++,"\n";

$res = $h -> getHistory() ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " if -w $file;
print "ok ",$idx++,"\n";

# this will chmod the file to rw
$res = $h -> changeLock(lock => 1,revision => '1.1' ) ;
warn join("\n",@$res),"\n" if $trace;
#print "not " unless -w $file;
print "not " unless defined $res ;

print "ok ",$idx++,"\n";

# this will NOT chmod the file back to r
$res = $h -> changeLock(lock => 0,revision => '1.1' ) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

chmod 0444,$file;

$res = $h -> checkOut(revision => '1.1', lock => 1) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

$res = $h -> checkArchive() ;
print "not " unless defined $res;
print "not " unless defined $res->[0] ;
print "ok ",$idx++,"\n";

open(FILE,">>$file") || die "open file failed\n";
print FILE "\nMore Dummy text\n";
close FILE ;

$res = $h -> checkIn
  (
   revision => '1.2',
   'log' => "2nd dummy log\nof a file\n"
  ) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

$res = $h -> getHistory() ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " if -w $file;
print "ok ",$idx++,"\n";

$res = $h -> getContent(revision => '1.1') ;
warn join("\n",@$res),"\n" if $trace;
print "not " 
  unless "@$res" eq "# \$Revision: 1.1 \$ Dummy text";
print "ok ",$idx++,"\n";

#$res = $h -> archiveLog('log' => "new dummy\nhistory for 1.1\n",
#                     state => 'Dummy', revision => '1.1') ;
#warn join("\n",@$res),"\n" if $trace;
#print "not " unless defined $res;
#print "ok ",$idx++,"\n";

#$res = $h -> getHistory() ;
#warn join("\n",@$res),"\n" if $trace;
#print "not " unless defined $res;
#print "not " unless scalar grep (/new dummy/,@$res) == 1;
#print "ok ",$idx++,"\n";

$res = $h -> showDiff(rev1 => '1.1', rev2 => '1.2') ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " unless index(join("\n",@$res),
'1c1
< # $Revision: 1.1 $
---
> # $Revision: 1.2 $
2a3,4
> 
> More Dummy text');
print "ok ",$idx++,"\n";

$res = $h -> checkArchive() ;
warn "@$res\n" if $trace;
print "not " unless defined $res;
print "ok ",$idx++,"\n";

