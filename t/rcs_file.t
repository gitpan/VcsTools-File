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
        print "1..26\n"; 
        $skipIt = 0 ;
      }
  }

END {print "not ok 1\n" unless $loaded;}
use Test;
use ExtUtils::testlib;
use VcsTools::File;
use VcsTools::LogParser ;
use VcsTools::DataSpec::HpTnd qw($description readHook);
require Tk::ErrorDialog; 
use Fcntl ;
use MLDBM qw(DB_File);
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0 ;

exit if $skipIt ;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package main ;

use strict ;

my $dbfile = 'test.db';
unlink($dbfile) if -r $dbfile ;

my %dbhash;
tie %dbhash,  'MLDBM',    $dbfile , O_CREAT|O_RDWR, 0640 or die $! ;

require VcsTools::DataSpec::Rcs ;
print "ok ",$idx++,"\n";


my $ds = new VcsTools::LogParser
  (
   description => $description,
   readHook => \&readHook
  ) ;
print "ok ",$idx++,"\n";

my $file = 'dummy.txt';

warn "heavy cleanup\n";
mkdir ('RCS', 0755) or die "Can't mkdir RCS:$!" unless -d 'RCS' ;
unlink ("RCS/$file,v") or die "Can't unlink RCS/$file,v:$!" 
  if -e "RCS/$file,v" ;
unlink ($file) or die "Can't unlink $file:$!" if -e $file ;

print "ok ",$idx++,"\n";

my $how = $trace ? 'warn' : undef ;

my $vf = new VcsTools::File 
  (
   storageArgs =>
   {
    dbHash => \%dbhash,
    keyRoot => 'root'
    },
   vcsClass => 'VcsTools::RcsAgent',
   name => 'dummy.txt',
   workDir => $ENV{'PWD'},
   dataScanner => $ds ,
   trace => $trace,
   how => $how,
  );
print "ok ",$idx++,"\n";

my $res;

print "create file\n" if $trace ;
open(FILE,">$file") || die "open file failed\n";
print FILE "# \$Revision\$\nDummy text\n";
close FILE ;
print "ok ",$idx++,"\n";

print "create archiveFile\n" if $trace ;
$res = $vf -> archiveFile();
print "not " unless defined $res;
print "not " if -w $file;
print "ok ",$idx++,"\n";

print "check out 1.1\n" if $trace ;
$res = $vf-> checkOut(revision => '1.1', lock => 1) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "enot " unless defined $res && $res;
print "ok ",$idx++,"\n";

# working on 1.1
open(FILE,">>$file") || die "open file failed\n";
print FILE "Dummy text for 1.1 -> 1.2\n";
close FILE ;
print "ok ",$idx++,"\n";

print "check in 1.2\n" if $trace ;
$res = $vf -> archiveFile(info =>{log => 'dummy log for 1.2'});
print "not " unless defined $res;
print "not " if -w $file;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "enot " unless defined $res && $res;
print "ok ",$idx++,"\n";

print "check out 1.1\n" if $trace ;
$res = $vf-> checkOut(revision => '1.1', lock => 1) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "enot " unless defined $res && $res;
print "ok ",$idx++,"\n";


open(FILE,">>$file") || die "open file failed\n";
print FILE "Dummy text for 1.1 -> 1.1.1.1\n";
close FILE ;
print "ok ",$idx++,"\n";

print "check in 1.1.1.1\n" if $trace ;
$res = $vf -> archiveFile(info =>{log => 'dummy log for 1.1.1.1'});
print "not " unless defined $res;
print "not " if -w $file;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

print "showdiff 1.1 1.2\n" if $trace ;
$res = $vf -> showDiff(rev1 => '1.1', rev2 => '1.2');
#print join("\n",@$res) ;
print "not " unless defined $res and index(join("\n",@$res),
'1c1
< # $Revision: 1.1 $
---
> # $Revision: 1.2 $
2a3
> Dummy text for 1.1 -> 1.2');
print "not " unless defined $res;
print "ok ",$idx++,"\n";


print "writeRevContent revision => '1.1'\n" if $trace ;
$res = $vf -> writeRevContent(revision => '1.1', fileName => 'toto.txt');
print "not " unless defined $res;
print "ok ",$idx++,"\n";

if (open(FIN,"toto.txt"))
  {
    my $str = join("",<FIN>);
    print "not " unless $str eq '# $Revision: 1.1 $'."\nDummy text\n" ; #';
  } 
else
  {
    print "not ";
  }
print "ok ",$idx++,"\n";

print "setUpMerge\n" if $trace ;
$res = $vf -> setUpMerge(ancestor => '1.1', below => '1.2', other => '1.1.1.1');
print "not " unless defined $res;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

print "not " unless (-e 'v1.1_dummy.txt' and -e 'v1.1.1.1_dummy.txt');
print "ok ",$idx++,"\n";

print "mergeCleanup\n" if $trace ;
$res = $vf-> mergeCleanup() ;
print "not " if (-e 'v1.1_dummy.txt' or -e 'v1.1.1.1_dummy.txt');
print "ok ",$idx++,"\n";

# emulate merge abort
$res = $vf->changeLock(lock => 0);
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

# modify the log of one file
# my @keys = $ds->getKeys() ;
# my $h=$vf->createHistory();
# my $o=$h->getVersionObj('1.1');
# my $info = $o->storage()->getDbInfo(@keys) ;
# $info->{keywords}= [qw/modified/];
# $vf->archiveLog(info => $info, revision => '1.1');
# my $histR=$vf->getHistory();
# print "not " unless grep(/\bmodified\b/,@$histR) == 1 ;
# print "ok ",$idx++,"\n";

exit;
