package VcsTools::RcsAgent ;

use strict;
use Carp;
use vars qw($VERSION %ClassData);
use File::stat ;
use Cwd;
use String::ShellQuote ;
use VcsTools::Process ;
use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;

%ClassData = (trace => 0,
              test => 0) ;

# translucent attribute (See Tom Christiansen's perltootc page)
# creates accessor methods for all keys of ClassData.
for my $datum (keys %ClassData)
  {
    no strict "refs";
    *$datum = sub 
      {
        my $self = shift ;
        my $class = ref($self) || $self ;
        unless (ref($self))
          {
            $ClassData{$datum} = shift if @_ ;
            return $ClassData{$datum} ;
          }
        $self->{$datum} = shift if @_ ;
        return defined $self->{$datum} ? $self->{$datum} : $ClassData{$datum};
      }
  }

# must pass the info data structure when creating it
# 1 instance per file object.
sub new
  {
    my $type = shift ;
    my %args = @_ ;

    my $self = {lastError => ''};

    # mandatory parameter
    foreach (qw/name workDir/)
      {
        die "No $_ passed to $type\n" unless defined $args{$_};
        $self->{$_} = delete $args{$_} ;
      }

    #optionnal, we may rely on the .fmrc
    foreach (keys %ClassData)
      {
        $self->{$_} = delete $args{$_} if defined $args{$_} ;
      }

    $self->{workDir} .= '/' unless $self->{workDir} =~ m!/$! ;
    $self->{fullName} = $self->{name} ;

    bless $self,$type ;
  }


1;

__END__

=head1 NAME

VcsTools::RcsAgent - Perl class to manage ONE RCS files..

=head1 SYNOPSIS

 my $h = new VcsTools::RcsAgent 
  (
   name => $file,
   workDir => $some_dir
  );

 $h -> getHistory() ;

 $h -> checkOut(revision => '1.51.1.1', lock => 1) ;

 $h -> getContent(revision => '1.52') ;

 $h -> checkArchive() ;

 $h -> changeLock(lock => 1,revision => '1.51.1.1' ) ;

 $h -> archiveLog(log => "new dummy\nhistory\n",
                     state => 'Dummy', revision => '1.52') ;

 $h -> showDiff(rev1 => '1.41') ;

 $h -> showDiff(rev1 => '1.41', rev2 => '1.43') ;

 $h -> checkIn(revision => '1.52', 
              'log' => "dummy log\Nof a file\n") ;


=head1 DESCRIPTION

This class is used to manage a RCS file. All functions are executed in
blocking mode. 

If you want to use other VCS system than RCS, you should copy or inherit this
file to implement your own new class.

=cut

#'

=head1 Class data

These items are translucent attributes (See L<perltootc> by Tom Christiansen).

Using the following method, you may set or query the value for the data
class. 

=over 4

=item *

trace: If set to 1, debug information are printed. (default 0)

=item *

test: If set to 1, each command will return the command to be executed
instead of the command result.(default 0)

=back

These parameters may be overridden for an object by 

=over 4

=item *

Passing a named parameters to the constructor 
(eg. C<trace =E<gt> 1>)

=item *

By invoking the corresponding object method 
(eg. C<$obj-E<gt>trace(1)>).

=back

=head1 Contructor

=head2 new(...)

Creates a new RCS agent class. Note that one RcsAgent must be created for 
each RCS file.

Parameters are (not including the class data):

=over 4

=item *

name: file name (mandatory)

=item *

workDir: local directory where the file is.

=item *

trace: If set to 1, debug information are printed.

=item *

test: each command will return the command to be executed instead of the
command result.

=back

=head1 Methods

=head2 spawn(...)

Spawn a new RCS agent object inheriting the attributes of the spawner object.

Parameters are :

=over 4

=item *

name: file name (mandatory)

=item *

subDir: Specify the directory of the spawned object relative to the
directory of the spawner object. Note that the workDir of the spawned
object will be set.

=back

=head2 create()

Create a new archive. If the RCS sub-directory is not present, it will also
be created.

Returns undef in case of problems.

=head2 checkOut(...)

Parameters are :

=over 4

=item *

revision: file revision to check out.

=item *

lock: boolean. whether to lock the file or not.

=back

Checks out revision x.y and lock it if desired.

Returns an array ref containing the output of the 'ci' in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 getContent(...)

Parameters are :

=over 4

=item *

revision: file revision to check out.

=back

Get the content of file revision x.y.

Returns an array ref of the file content in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 checkArchive()

Check the state of the archive with respect to the passed revision. 

Parameters are :

=over 4

=item *

revision: revision number of the user's working file. May be undef.

=back

Returns an array ref made of [$rev,$locker,$time] or undef in case of problems.

=over 4

=item *

$time is the time of the last modification of the archive (in epoch, decimal
time)

=item *

if the revision the the user is working is locked, $locker returns the
name of the locker, 'unlocked' otherwise.

=item *

$revision is there for historical reasons. It returns the revision number 
of the user's working file if this rev is locked. Is undef otherwise.

=back

=head2 changeLock(...)

Parameters are :

=over 4

=item *

revision: file revision to check out.

=item *

lock: whether to lock the file or not.

=back

Change the lock of the file for revision x.y.

Returns an array ref containing the output of the 'rcs' in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.


=head2 archiveLog(...)

Will modify the log (not the file) of a specified revision of the file. 

Parameters are :

=over 4

=item *

revision

=item *

log: log to store in the history of revision

=item *

state: new state to store

=back

Returns an array ref containing the output of the 'futil' in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 getHistory()

Gets the complete history of file.

Returns an array ref containing the history in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 showDiff(...)

Parameters are :

=over 4

=item *

rev1: first revision to compare

=item *

rev2: 2nd revision to compare. If not specified, the comparison is made 
between the local file and revision 'rev1'.

=back

Gets the diff between current file and revision rev1 or between rev1 and
rev2 if rev2 is specified.

Returns an array ref containing the diff output in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 create()

Create the RCS file.

Returns an array ref containing the output of the 'ci' commmand in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 checkIn(...)

Archive (check in) the current file. Parameters are :

=over 4

=item *

revision

=item *

log: log to store in the history of revision

=back

Returns an array ref containing the output of the 'ci' commmand in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 list()

Returns an array reference containing all RCS files found in the RCS
directory of this file 

For instance, list will return ['foo','bar'] if the RCS subdir contains
foo,v and bar,v.

Returns undef in case of problem.


=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), VcsTools::Process(3)

=cut



sub printDebug
  {
    my $self=shift ;
    
    print shift if $self->{trace} ;
  }

sub error
  {
     my $self=shift ;
     return $self->{lastError} ;
  }

sub checkOut
  {
    my $self = shift ;
    my %args = @_ ;

    foreach (qw/revision lock/)
      {
        die "No $_ passed to $self->{name}::checkOut\n" unless 
          defined $args{$_};
      }

    $self->printDebug
      ("Check out $self->{name} rev $args{revision} lock $args{lock}\n");

    my $opt = $args{lock} ? '-l ' : '' ;
    my $run = "co $opt -r$args{revision} ".
      $self->{fullName} ;

    return $run if $self->{test};

    my $ret = openPipe
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       command => $run
      );

    $self->{lastError} = getError unless defined $ret ;
    return $ret ;
  }


sub getContent
  {
    my $self = shift ;
    my %args = @_ ;

    foreach (qw/revision/)
      {
        die "No $_ passed to $self->{name}::getContent\n" unless 
          defined $args{$_};
      }

    $self->printDebug("reading content of $self->{name} rev $args{revision}\n");
    
    my $run = "co -p -r$args{revision} ".
      $self->{fullName} ;

    return $run if $self->{test};

    my $ret = openPipe 
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       command => $run
      );

    $self->{lastError} = getError unless defined $ret ;
    return $ret ;
  }

sub checkArchive
  {
    my $self = shift ;
    my %args = @_ ;

    unless (exists $args{revision})
      {
        carp "No revision parameter passed to checkArchive\n";
      }

    $self->{rcsDir} = $self->{workDir} ;
    $self->{rcsDir} .= -d $self->{workDir} . 'RCS' ? "RCS/" : '' ;
    my $rcsFile = $self->{rcsDir}. $self->{fullName}.',v' ;

    $self->printDebug("checking archive of $self->{name} ($rcsFile)\n");

    my $run ;
    if ($self->{test})
      {
        $run = "Running stat on $rcsFile\n";
      }

    unless (-e $rcsFile)
      {
        $self->{lastError}="RCS archive file $rcsFile does not exists\n";
        return undef;
      }

    my $st = stat($rcsFile) or die "Internal error:No $rcsFile: $!";
    my $mtime = $st->mtime ;
    
    return [undef,undef,$mtime] unless defined $args{revision} ;
    
    $run = "rlog $self->{fullName}";

    return $run if $self->{test};

    local $_ ;

    my $oldDir = cwd();

    unless ( chdir ($self->{workDir}))
      {
        $self->{lastError}="Can't cd to $args{workDir}:$!";
        return undef;
      } 

    unless (open(FIN,"$run |") )
      {
        $self->{lastError}="open pipe $run failed:$!";
        chdir $oldDir;
        return undef;
      }

    while (<FIN>)
      {
        if (/^revision +([\d\.]+)\s+locked by: *(\w+)/)
          {
            # print "line is $_\nlocker $2, rev $1\n";
            chdir $oldDir;
            return [$1,$2,stat($rcsFile)->mtime] 
              if $1 eq $args{revision};
          };
      }

    close FIN;

    chdir $oldDir;
    return [undef,undef,stat($rcsFile)->mtime];

  }


sub changeLock
  {
    my $self = shift ;
    my %args = @_ ;

    foreach (qw/lock revision/)
      {
        die "No $_ passed to $self->{name}::changeLock\n" unless 
          defined $args{$_};
      }

    my $str = $args{lock} ? '' : 'not ';
    $self->printDebug("changing $self->{name} to ".$str."locked\n");
    
    my $opt = $args{lock} ? '-l' : '-u' ;
    my $run = "rcs $opt$args{revision} ".
      $self->{fullName} ;

    return $run if $self->{test};

    return mySystem
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       command => $run
      );
  }

sub archiveLog
  {
    my $self = shift ;
    my %args = @_ ;

    foreach (qw/revision log state/)
      {
        die "No $_ passed to $self->{name}::archiveLog\n" unless 
          defined $args{$_};
      }

    croak "Archive log not available with RCS";

    $self->printDebug("Archiving log for revision $args{revision} ".
                    "state $args{state} log is:\n$args{'log'}");
    
    my $run1 = "futil  $self->{hostOption} ".
      "-s$args{state}:$args{revision} $self->{fullName} 2>&1" ;
    my $run2 = "futil  $self->{hostOption} -m$args{revision}:" .
      shell_quote($args{'log'}) . " $self->{fullName} 2>&1" ;

    return $run1."\n".$run2 if $self->{test};

    foreach my $run ($run1,$run2)
      {
        my $ret = mySystem
          (
           workDir => $self->{workDir}, 
           trace => $self->{trace},
           command => $run
          );

        unless (defined $ret)
          {
            $self->{lastError} = getError ;
            return $ret ;
          }
      }
    
    return 1;
  }

sub getHistory
  {
    my $self = shift ;
    my %args = @_;

    my $run =  "rlog $self->{fullName} 2>&1";
    $self->printDebug("getHistory of $self->{name}\n");

    return $run if $self->{test};

    my $ret = openPipe
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       command => $run
      );

    $self->{lastError} = getError unless defined $ret ;
    return $ret ;
  }

sub showDiff
  {
    my $self = shift ;
    my %args = @_ ;

    foreach (qw/rev1/)
      {
        die "No $_ passed to $self->{name}::showDiff\n" unless 
          defined $args{$_};
      }

    my $rev2 = $args{rev2} ; # may not be defined if diff with local file

    my $str = defined $rev2 ? $rev2 : 'local file' ;
    $self->printDebug("Diff for $args{rev1} and $str\n");

    my $revStr = "-r$args{rev1}" ;
    $revStr .= " -r$args{rev2}" if defined $args{rev2} ;

    my $cmd = "rcsdiff $revStr $self->{fullName} 2>&1" ;

    return $cmd if $self->{test};

    my $ret = openPipe
      (
       command => $cmd, 
       expect => {0 => 1, 256 => 1},
       workDir => $self->{workDir}, 
       trace => $self->{trace}
      );
    
    $self->{lastError} = getError unless defined $ret ;
    return $ret ;
  }

sub create
  {
    my $self = shift ;
    my %args = @_;

    $args{revision} = '1.1' unless defined $args{revision} ;
    $args{description} = 'no description given' 
      unless defined $args{description};
    chomp($args{description});

    my $res = $self->checkArchive() unless defined $self->{rcsDir};

    croak "Error: Can't create archive because the archive already exists" 
      if defined $res;

    if ($self->{rcsDir} eq $self->{workDir})
      {    
        $self->{rcsDir} .= 'RCS/';
        $self->printDebug("Creating RCS directory $self->{rcsDir}\n");
        mkdir($self->{rcsDir},0755) or die "Can't create $self->{rcsDir}";
      }

    $self->printDebug("Creating RCS file for $self->{name} rev $args{revision}\n");

    my $run = "ci -u -r$args{revision} $self->{fullName} 2>&1" ;

    return $run if $self->{test};

    my $ret = pipeIn
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       expect => { 0 => 1, 256 => 1},
       input => $args{description}."\n.\n",
       command => $run
      );

    $self->{lastError} = getError unless defined $ret ;
    return $ret ;
  }

sub checkIn
  {
    my $self = shift ;
    my %args = @_ ;

    foreach (qw/log revision/)
      {
        die "No $_ passed to $self->{name}::checkIn\n" unless 
          defined $args{$_};
      }

    $self->printDebug("Checking in $self->{name} rev $args{revision}\n");

    my $run = "ci -u -r$args{revision} -m".
      shell_quote($args{'log'}) . " $self->{fullName} 2>&1" ;

    return $run if $self->{test};

    my $ret = mySystem
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       command => $run
      );

    $self->{lastError} = getError unless defined $ret ;
    return $ret ;
  }

# returns the list of buddies in the same RCS directory
sub list
  {
    my $self=shift ;
    my %args = @_ ;
    
    $self->checkArchive(revision => undef) unless defined $self->{rcsDir};
    $args{dir} = $self->{rcsDir} unless defined $args{dir};

    unless (defined $args{dir})
      {
        $self->printDebug("list for $self->{name}: Undefined dir to list\n");
        return $self->{test} ? '' : undef ;
      }

    $self->printDebug("Listing RCS dir $args{dir}\n");

    opendir(DIR,$self->{rcsDir}) or die "Can't opendir $self->{rcsDir}";
    
    my %ret ;
    foreach my $name (grep(s/,v$//,readdir(DIR)))
      {
        $ret{$name} = {
                       revision => undef,
                       locker => undef,
                       time => stat($self->{rcsDir}.$name.',v')->mtime 
                      };
      }

    close DIR;

    return \%ret;
  }

sub spawn
  {
    my $self = shift ;
    my %args = @_ ;

    croak "No name passed to $self->{name}::spawn\n" unless 
      defined $args{name};

    my %new ;

    foreach my $k (keys %ClassData)
      {
        $new{$k} = $self->{$k} if defined $self->{$k} ;
      }
    
    $new{workDir}=$self->{workDir} ;
    $new{workDir} .= '/'.$args{subDir} if defined $args{subDir} ;

    return ref($self)->new 
      (
       name => $args{name},
       %new
      ) ;
  }

1;
