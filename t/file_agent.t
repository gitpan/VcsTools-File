# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use ExtUtils::testlib;
use Cwd ;
use VcsTools::FileAgent;
$loaded = 1;
my $idx = 1;
print "ok ",$idx++,"\n";
my $trace = shift || 0;

######################### End of black magic.


use strict ;

my $dtest = "test_agent";

-d $dtest or mkdir($dtest,0755) or die "can't make dir $dtest \n";

print "ok ",$idx++,"\n";

my $agent = "VcsTools::FileAgent" ;
my $file = 'test.txt';
my $fa = new $agent(name => $file,
                    trace => $trace,
                    workDir => cwd().'/'.$dtest);
print "ok ",$idx++,"\n";

my $fname = $dtest.'/'.$file ;
my $res ;

warn "writing 3 files \n" if $trace ;
$res = $fa->writeFile(content => '$Revision: 1.46 $ '."\n\ndummy content\n");
print "not " unless -e $fname ;
print "ok ",$idx++,"\n";

$res = $fa->writeFile(content => "dummy content\n\n_1\n",name => 'test_1.txt');
print "not " unless -e $dtest.'/test_1.txt';
print "ok ",$idx++,"\n";

$res = $fa->writeFile(content => "dummy content\n\n_2\n",name => 'test_2.txt');
print "not " unless -e $dtest.'/test_2.txt';
print "ok ",$idx++,"\n";

warn "reading 1 file\n" if $trace ;
$res = $fa->readFile(name => 'test.txt') ;
print "NOT " unless defined $res ;
warn join("",@$res),"\n" if $trace ;
print "not " unless 
  join('',@$res) eq '$Revision: 1.46 $ '."\n\ndummy content\n";
print "ok ",$idx++,"\n";

warn "reading revision \n" if $trace ;
$res = $fa->getRevision(name => 'test.txt') ;
print "not " unless defined $res ;
print "not " unless $res eq '1.46';
print "ok ",$idx++,"\n";

my $ans = 0  ;
if ($trace)
  {
    print "perform xemacs test ? (y/n)";
    my $rep = <STDIN> ;
    chomp ($rep);
    $ans = $rep eq 'y' ? 1 : 0 ;
  }

my $gnuc = `type gnuclient` ;
if ($ans and $gnuc =~ m!/!)
  {
    # gnuclient was found ...
    warn "editing 1 file\n" if $trace ;
    $res = $fa->edit(callback => \&statcb) ;
  }
else
  {
    warn "skipping edit test" if $trace ;
    print "ok ",$idx++,"\n";
  }


$gnuc = `type gnudoit` ;
if ($ans and $gnuc =~ m!/!)
  {
    warn "merging the 3 files\n" if $trace ;
    $res = $fa->merge(callback => \&statcb, 
               below => 'test_1.txt', other => 'test_2.txt',
               ancestor => 'test.txt') ;
  }
else
  {
    warn "skipping merge test" if $trace ;
    print "ok ",$idx++,"\n";
  }

warn "stat file\n" if $trace ;
$res = $fa->stat(name => 'test.txt') ;
print "not " unless defined $res ;
print "ok ",$idx++,"\n";

warn "stat non existing file, failure trace is normal\n" if $trace ;
$res = $fa->stat(name => 'nofile.txt') ;
print "not " if defined $res ;
print "ok ",$idx++,"\n";

warn "See if file exist\n" if $trace ;
$res = $fa->stat(name => 'test.txt') ;
print "ok ",$idx++,"\n";



