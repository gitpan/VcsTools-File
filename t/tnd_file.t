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
        print "1..30\n"; 
        $skipIt = 0 ;
      }
  }

END {print "not ok 1\n" unless $loaded;}
use Test;
use ExtUtils::testlib;
use VcsTools::File;
use VcsTools::LogParser ;
use VcsTools::HmsAgent ;
use Puppet::Storage ;
use Cwd ;
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

require VcsTools::DataSpec::HpTnd ;
print "ok ",$idx++,"\n";


my $ds = new VcsTools::LogParser
  (
   description => $description,
   readHook => \&readHook
  ) ;
print "ok ",$idx++,"\n";

my $file = 'dummy.txt';
my $dir = 'my_tnd/dir';
my $origDir = cwd();

warn "heavy cleanup\n" if $trace;
system("rm -rf my_tnd ; rm -rf .tiedHashes; futil -u -hhptnofs /test_integ/my_tnd/dir/dummy.txt;echo y|futil -x -hhptnofs /test_integ/my_tnd/dir/dummy.txt" );
print "ok ",$idx++,"\n";

my $how = $trace ? 'warn' : undef ;

Puppet::Storage->dbHash(\%dbhash);
Puppet::Storage->keyRoot('root');

VcsTools::HmsAgent->hmsBase('test_integ');
VcsTools::HmsAgent->hmsDir($dir);
VcsTools::HmsAgent->hmsHost('hptnofs');
VcsTools::HmsAgent->trace($trace);

my $agent = VcsTools::HmsAgent->new
  (
   name => 'dummy.txt',
   workDir => cwd().'/'.$dir
  );

my $vf = new VcsTools::File 
  (
   storage=> new Puppet::Storage(name => 'dummy.txt') ,
   vcsAgent => $agent,
   name => 'dummy.txt',
   workDir => cwd().'/'.$dir,
   dataScanner => $ds ,
   trace => $trace,
   how => $how,
  );
print "ok ",$idx++,"\n";

my $res;

chdir $dir or die "can't chdir $dir\n";
open(FILE,">$file") || die "open file failed\n";
print FILE "# \$Revision\$\nDummy text\n";
close FILE ;
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

warn "Read content\n" if $trace;
$res = $vf->getContent();
print "not " unless (defined $res and 
                     join('',@$res) eq "# \$Revision\$\nDummy text\n");
print "ok ",$idx++,"\n";

# check chmod
print "chmod +x\n" if $trace;
$vf->chmodFile(mode =>'+x');
chdir $dir or die "can't chdir $dir\n";
print "not " unless -x $file ;
print "ok ",$idx++,"\n";

#chmod back with different starting dir
print "chmod -x\n" if $trace;
$vf->chmodFile(mode =>'a-x');
print "not " if -x $file ;
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";


$res = $vf -> archiveFile();
print "not " unless defined $res;
chdir $dir or die "can't chdir $dir\n";
print "not " if -w $file;
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

$res = $vf-> checkOut(revision => '1.1', lock => 1) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "enot " unless defined $res && $res;
print "ok ",$idx++,"\n";

# working on 1.1
chdir $dir or die "can't chdir $dir\n";
open(FILE,">>$file") || die "open file failed\n";
print FILE "Dummy text for 1.1 -> 1.2\n";
close FILE ;
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

$res = $vf -> archiveFile(info =>{log => 'dummy log for 1.2'});
print "not " unless defined $res;
chdir $dir or die "can't chdir $dir\n";
print "not " if -w $file;
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "enot " unless defined $res && $res;
print "ok ",$idx++,"\n";



$res = $vf-> checkOut(revision => '1.1', lock => 1) ;
warn join("\n",@$res),"\n" if $trace;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "enot " unless defined $res && $res;
print "ok ",$idx++,"\n";

chdir $dir or die "can't chdir $dir\n";
open(FILE,">>$file") || die "open file failed\n";
print FILE "Dummy text for 1.1 -> 1.1.1.1\n";
close FILE ;
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

$res = $vf -> archiveFile(info =>{log => 'dummy log for 1.1.1.1'});
print "not " unless defined $res;
chdir $dir or die "can't chdir $dir\n";
print "not " if -w $file;
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

$res = $vf -> showDiff(rev1 => '1.1', rev2 => '1.2');
print "not " unless "@$res" eq '/test_integ/my_tnd/dir/dummy.txt[1.1] <  > [1.2] 1c1 < # $Revision: 1.1 $ --- > # $Revision: 1.2 $ 2a3 > Dummy text for 1.1 -> 1.2';
print "not " unless defined $res;
print "ok ",$idx++,"\n";

$res = $vf -> writeRevContent(revision => '1.1', fileName => 'toto.txt');
print "not " unless defined $res;
print "ok ",$idx++,"\n";

chdir $dir or die "can't chdir $dir\n";
if (open(FIN,"toto.txt"))
  {
    my $str = join("",<FIN>);
    print "not " unless $str eq '# $Revision: 1.1 $'."\nDummy text\n" ; #';
  } 
else
  {
    print "not ";
  }
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

$res = $vf -> setUpMerge(ancestor => '1.1', below => '1.2', other => '1.1.1.1');
print "not " unless defined $res;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

chdir $dir or die "can't chdir $dir\n";
print "not " unless (-e 'v1.1_dummy.txt' and -e 'v1.1.1.1_dummy.txt');
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

$res = $vf-> mergeCleanup() ;
chdir $dir or die "can't chdir $dir\n";
print "not " if (-e 'v1.1_dummy.txt' or -e 'v1.1.1.1_dummy.txt');
chdir $origDir or die "can't chdir $origDir\n";
print "ok ",$idx++,"\n";

# emulate merge abort
$res = $vf->changeLock(lock => 0);
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

$res = $vf-> checkError() ;
print "not " unless defined $res && $res;
print "ok ",$idx++,"\n";

# modify the log of one file
my @keys = $ds->getKeys() ;
my $h=$vf->createHistory();
my $o=$h->getVersionObj('1.1');
my $info = $o->storage()->getDbInfo(@keys) ;
$info->{keywords}= [qw/modified/];
$vf->archiveLog(info => $info, revision => '1.1');
my $histR=$vf->getHistory();
print "not " unless grep(/\bmodified\b/,@$histR) == 1 ;
print "ok ",$idx++,"\n";


exit;
