# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $skipIt ;
BEGIN 
  { 
    $| = 1; 
    if (system('fls -hhptnofs /test_integ>/dev/null') ne 0)
      {
        warn "You don't have access to the test_integ HMS base on hptnofs\n",
        "Which is normal if you are not working at HP TID in Grenoble, France\n",
        "Skipping most of this test\n";
        print "1..1\n";
        $skipIt = 1;
      }
    else
      {
        print "1..17\n"; 
        $skipIt = 0 ;
      }
  }

END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use VcsTools::HmsAgent;
use File::Path;
use Cwd ;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

use strict ;

exit if $skipIt ;

my $trace = shift || 0 ;


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $file = 'dummy.txt';
my $dir = 'a_not/so_dummy/dir';
my $fullName = $dir.'/'.$file ;
my $origDir = cwd() ;

sub ckd { croak("Stuck in wrong directory",cwd()) unless $origDir=cwd();}

warn "heavy cleanup\n";
system("rm -rf a_not;futil -u -hhptnofs /test_integ/a_not/so_dummy/dir/dummy.txt;echo y|futil -x -hhptnofs /test_integ/a_not/so_dummy/dir/dummy.txt" );
system("futil -x /test_integ/a_not/so_dummy/dir; futil -x /test_integ/a_not/so_dummy; futil -x /test_integ/a_not");
print "ok ",$idx++,"\n";

unless (-d $dir)
  {
    mkpath($dir,1,0755) or die "can't mkpath $dir";
  }

VcsTools::HmsAgent->hmsHost('hptnofs') ;
VcsTools::HmsAgent->hmsDir($dir) ;
VcsTools::HmsAgent->hmsBase('test_integ') ;
VcsTools::HmsAgent->trace($trace);

my $h = new VcsTools::HmsAgent 
  (
   name => $file,
   workDir => $dir
  );

print "ok ",$idx++,"\n";
my $res ;

ckd ;

warn "normal error below\n";
$res = $h -> checkArchive(revision => undef) ;
print "not " if defined $res;
print "ok ",$idx++,"\n";

ckd ;

chdir $dir or die "can't chdir to $dir";
open(FILE,">$file") || die "open file failed\n";
print FILE "# \$Revision\$\nDummy text\n";
close FILE ;
chdir $origDir ;

print "create\n" if $trace ;
$res = $h -> create();
warn "@$res\n" if $trace;
print "not " unless defined $res;
print "not " if -w $fullName;
print "ok ",$idx++,"\n";

ckd ;

print "getHistory\n" if $trace ;
$res = $h -> getHistory() ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " if -w $fullName;
print "ok ",$idx++,"\n";

ckd ;

# this will chmod the file to rw
print "changeLock to 1\n" if $trace ;
$res = $h -> changeLock(lock => 1,revision => '1.1' ) ;
warn "$fullName not writable\n" if ($trace and not -w $fullName);
print "not " unless -w $fullName;
print "not " unless defined $res ;

ckd ;

print "ok ",$idx++,"\n";

# this will NOT chmod the file back to r
print "changeLock to 0\n" if $trace ;
$res = $h -> changeLock(lock => 0,revision => '1.1' ) ;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

ckd ;

chdir $dir or die "can't chdir to $dir";
chmod 0444,$file;
chdir $origDir ;

print "checkOut 1.1\n" if $trace ;
$res = $h -> checkOut(revision => '1.1', lock => 1) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

ckd ;

chdir $dir or die "can't chdir to $dir";
open(FILE,">>$file") || die "open file failed\n";
print FILE "\nMore Dummy text\n";
close FILE ;
chdir $origDir ;

print "checkIn 1.2\n" if $trace ;
$res = $h -> checkIn
  (
   revision => '1.2',
   'log' => "2nd dummy log\nof a file\n"
  ) ;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";
ckd ;


print "getHistory\n" if $trace ;
$res = $h -> getHistory() ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " if -w $fullName;
print "ok ",$idx++,"\n";

ckd ;

print "getContent of 1.1\n" if $trace ;
$res = $h -> getContent(revision => '1.1') ;
warn join("\n",@$res),"\n" if $trace;
print "not " 
  unless "@$res" eq "# \$Revision: 1.1 \$ Dummy text";
print "ok ",$idx++,"\n";

ckd ;

print "archiveLog of 1.1\n" if $trace ;
$res = $h -> archiveLog('log' => "new dummy\nhistory for 1.1\n",
                     state => 'Dummy', revision => '1.1') ;
print "not " unless defined $res;
print "ok ",$idx++,"\n";

ckd ;

print "getHistory\n" if $trace ;
$res = $h -> getHistory() ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " unless scalar grep (/new dummy/,@$res) == 1;
print "ok ",$idx++,"\n";

ckd ;

print "showDiff\n" if $trace ;
$res = $h -> showDiff(rev1 => '1.1', rev2 => '1.2') ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " unless join("\n",@$res) eq 
'/test_integ/a_not/so_dummy/dir/dummy.txt[1.1] <  > [1.2]
1c1
< # $Revision: 1.1 $
---
> # $Revision: 1.2 $
2a3,4
> 
> More Dummy text';
print "ok ",$idx++,"\n";

ckd ;

print "checkArchive 1.3\n" if $trace ;
$res = $h -> checkArchive(revision => '1.3') ;
print "not " unless defined $res;
print "not " if defined $res->[0];
print "ok ",$idx++,"\n";

ckd ;

print "list\n" if $trace ;
$res = $h -> list() ;
warn "Found file ",join(' ',keys %$res),"\n" if defined $res and $trace;
print "not " unless (defined $res and 
                     join(' ',keys %$res) eq 'dummy.txt') ;
print "ok ",$idx++,"\n";

ckd ;

