# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $skipIt ;
BEGIN 
  { 
    $| = 1; 
    if (system('rcs>/dev/null') > 512)
      {
        warn "You don't have the RCS VCS system\n",
        "Skipping most of this test\n";
        print "1..1\n";
        $skipIt = 1;
      }
    else
      {
        print "1..16\n"; 
        $skipIt = 0 ;
      }
  }

END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use Cwd;
use Carp ;
use File::Path ;

use VcsTools::RcsAgent;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";

######################### End of black magic.

my $trace = shift || 0 ;


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $file = 'dummy.txt';
my $dir = 'my_rcs/work/';
my $fullName = $dir.'/'.$file ;
my $origDir = cwd();

sub ckd { croak("Stuck in wrong directory",cwd()) unless $origDir=cwd();}

warn "heavy cleanup\n";
if (-d "my_rcs")
  {
    system("rm -rf my_rcs") && die "Can't cleanup my_rcs dir";
  }

mkpath([$dir],1) unless -d $dir ;



print "ok ",$idx++,"\n";

my $h = new VcsTools::RcsAgent 
  (
   name => $file,
   trace => $trace,
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

chdir $dir or die "can't chdir $dir\n";
open(FILE,">$file") || die "open file failed\n";
print FILE "# \$Revision\$\nDummy text\n";
close FILE ;
chdir $origDir or die "can't chdir $origDir\n";

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

print "changeLock to 1\n" if $trace ;
# this will chmod the file to rw
$res = $h -> changeLock(lock => 1,revision => '1.1' ) ;
warn join("\n",@$res),"\n" if $trace;
#print "not " unless -w $fullName;
print "not " unless defined $res ;

ckd ;

print "ok ",$idx++,"\n";

print "changeLock to 0\n" if $trace ;
# this will NOT chmod the file back to r
$res = $h -> changeLock(lock => 0,revision => '1.1' ) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

ckd ;

chmod 0444,$fullName;

print "checkOut 1.1\n" if $trace ;
$res = $h -> checkOut(revision => '1.1', lock => 1) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

ckd ;

print "checkArchive 1.1\n" if $trace ;
$res = $h -> checkArchive(revision => 1.1) ;
warn $h->error unless defined $res;
warn join("\n",@$res),"\n" if $trace && defined $res;
print "not " unless defined $res && defined $res->[0] && $res->[0] eq '1.1';
print "ok ",$idx++,"\n";

ckd ;

chdir $dir or die "can't chdir $dir\n";
open(FILE,">>$file") || die "open $file failed\n";
print FILE "\nMore Dummy text\n";
close FILE ;
chdir $origDir or die "can't chdir $origDir\n";

ckd ;

print "checkIn 1.2\n" if $trace ;
$res = $h -> checkIn
  (
   revision => '1.2',
   'log' => "2nd dummy log\nof a file\n"
  ) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

ckd ;

print "getHistory\n" if $trace ;
$res = $h -> getHistory() ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "ok ",$idx++,"\n";

ckd ;

print "getContent\n" if $trace ;
$res = $h -> getContent(revision => '1.1') ;
warn join("\n",@$res),"\n" if $trace;
print "not " 
  unless "@$res" eq "# \$Revision: 1.1 \$ Dummy text";
print "ok ",$idx++,"\n";

ckd ;

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

print "showDiff\n" if $trace ;
$res = $h -> showDiff(rev1 => '1.1', rev2 => '1.2') ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res;
print "not " unless defined $res && index(join("\n",@$res),
'1c1
< # $Revision: 1.1 $
---
> # $Revision: 1.2 $
2a3,4
> 
> More Dummy text');
print "ok ",$idx++,"\n";

ckd ;

print "checkArchive\n" if $trace ;
$res = $h -> checkArchive(revision => '1.2') ;
warn "@$res\n" if $trace;
print "Not " unless defined $res;
print "not " if defined $res->[1];
ckd ;

print "ok ",$idx++,"\n";

print "list\n" if $trace ;
$res = $h -> list() ;
warn "Found file ",join(' ',keys %$res),"\n" if defined $res and $trace;
print "not " unless (defined $res and 
                     join(' ',keys %$res) eq 'dummy.txt') ;
print "ok ",$idx++,"\n";

ckd ;
