package VcsTools::HmsAgent ;

use strict;
use Carp;
use vars qw($VERSION);
use String::ShellQuote ;
use VcsTools::Process ;
use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

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
    foreach (qw/hmsHost hmsBase hmsDir trace test/)
      {
        $self->{$_} = delete $args{$_} ;
      }

    $self->{hostOption} = defined $self->{hmsHost} ? 
      '-h'.$self->{hmsHost} :'';

    $self->{fullName} = $self->{name} ;

    if (defined $self->{hmsBase})
      {
         $self->{fullName} = "$self->{hmsDir}/". $self->{fullName} if 
           defined $self->{hmsDir};
         $self->{fullName} = "/$self->{hmsBase}/". $self->{fullName};
         $self->{fullName}  =~ s!//!/!g ;
      }

    bless $self,$type ;
  }


1;

__END__

=head1 NAME

VcsTools::HmsAgent - Perl class to manage ONE HMS files..

=head1 SYNOPSIS

 my $h = new VcsTools::HmsAgent 
  (
   hmsBase => 'test_integ',
   hmsHost => 'hptnofs',
   name => $file,
   trace => $trace,
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

This class is used to manage a HMS file. All functions are executed in
blocking mode. 

If you want to use other VCS system than HMS, you should copy or inherit this
file to implement your own new class.

=head1 HMS

HMS is Hewlett-Packard proprietary VCS system based on RCS. This product
is part of HP SoftCM.

=cut

#'

=head1 Contructor

=head2 new(...)

Creates a new HMS agent class. Note that one HmsAgent must be created for 
each HMS file.

Parameters are :

=over 4

=item *

name: file name (mandatory)

=item *

hmsHost: Specify the HMS server name.

=item *

hmsBase: Specify the HMS base name.

=item *

hmsDir: Specify the directory relative to the HMS base where the file
is archived.

=item *

workDir: local directory where the file is.

=item *

trace: If set to 1, debug information are printed.

=item *

test: each command will return the command to be executed instead of the
command result.

=back

If 'hmsHost' or 'hmsBase' parameters are not provided, HMS will rely on 
the system or user .fmrc file. See fci(1) for more details.

=head1 Methods

=head2 checkOut(...)

Parameters are :

=over 4

=item *

revision: file revision to check out.

=item *

lock: boolean. whether to lock the file or not.

=back

Checks out revision x.y and lock it if desired.

Returns an array ref containing the output of the 'fci' in case of
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

if the revision the the user is working on is locked, $locker returns the
name of the locker, 'unlocked' otherwise.

=item *

$revision is there for historical reasons. It is set to the revision number 
of the user's working file if this revision is locked. set to undef otherwise.

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

Returns an array ref containing the output of the 'futil' in case of
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

Create the HMS file. If needed this method will also create the HMS path
in the HMS base.

Returns an array ref containing the output of the 'fci' commmand in case of
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

Returns an array ref containing the output of the 'fci' commmand in case of
success, undef in case of problems.

In case of problem, you can call the error() method to get the STDOUT
of the command.

=head2 list()

Returns a hash reference containing all HMS files found in the HMS
base in the directory of this file and all sub-directories (i.e list
recursively all files found in and below /hmsBase/hmsDir).

The hash will contains the locker and locked revision (if any) and the
last modification time of the HMS archive.

For instance, list will return :
 {'foo' => {rev => '1.0', locker => 'bob', time => '935143309'},
  'subdir/bar' => {rev => undef , locker => undef, time => '935143305'}}


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
    my $run = "fco $opt$self->{hostOption} -r$args{revision} ".
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
    
    my $run = "fco -p -r$args{revision} $self->{hostOption} ".
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

    $self->printDebug("checking archive of $self->{name}\n");

    my $run = "fll -N $self->{hostOption} ". $self->{fullName} ;

    return $run if $self->{test};

    my $result = openPipe 
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       command => $run
      );

    if (defined $result)
      {
        my ($mode,$locker,$size,$time,$name,$rev) = 
          split (/[\s\[\]]+/, shift @$result) ;
        if (defined $args{revision} and defined $rev and 
            $args{revision} eq $rev)
          {
            return [$rev,$locker,$time];
          }
        else
          {
            return [undef,undef,$time] ;
          }
      }
    else
      {
        $self->{lastError} = getError ;
        return undef ;
      }
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
    my $run = "futil $opt $self->{hostOption} -r$args{revision} ".
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

    my $run =  "fhist $self->{hostOption} $self->{fullName} 2>&1";
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

    my $cmd = "fdiff $self->{hostOption} $revStr $self->{fullName} 2>&1" ;

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
    my %args = @_ ;

    croak("$self->{name}::create: Cannot specify a revision to create ",
          "with HMS.\n" )
      if defined $args{revision};

    my $run = "fci -auto $self->{hostOption} -u $self->{fullName}" ;

    my $ret = $self->mkHmsDir() ;
    $self->{lastError} = getError unless defined $ret ;
    $self->printDebug($self->{lastError}) unless defined $ret ;

    $self->printDebug("Creating HMS file $self->{name}\n");

    return $ret.$run if $self->{test};

    $ret = openPipe
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
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

    my $run = "fci $self->{hostOption} -u -r$args{revision} -m".
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

sub mkHmsDir
  {
    my $self= shift;

    my %args = @_;

    foreach my $what (qw/hmsHost hmsBase hmsDir/)
      {
        $args{$what} = $self->{$what} unless defined $args{$what};
      }

    unless (defined $args{hmsDir})
      {
        $self->printDebug("makeHmsDir for $self->{name}: Undefined dir to make\n");
        return $self->{test} ? '' : undef ;
      }

    $self->printDebug("Creating HMS dir $args{hmsDir}\n");

    my $ret;
    my $run = "futil -M " ;
    $run .= "-h$args{hmsHost} " if defined $args{hmsHost};
    $run .= "/$args{hmsBase}" if defined $args{hmsBase} ;

    my $all = '';
    foreach my $d (split '/',$args{hmsDir})
      {
        next if $d eq ''; 
        $run .= '/'.$d;
        
        if ($self->{test})
          {
            $all .= $run."\n";
            next;
          }

        $ret = openPipe
          (
           #trace => $self->{trace},
           command => $run
          );
        print getError unless defined $ret;
      }
    
    return $all if $self->{test};
  }

# returns the list of buddies in the same HMS directory
sub list
  {
    my $self=shift ;
    my %args = @_ ;
    
    foreach my $what (qw/hmsHost hmsBase hmsDir/)
      {
        $args{$what} = $self->{$what} unless defined $args{$what};
      }

    unless (defined $args{hmsDir})
      {
        $self->printDebug("list for $self->{name}: Undefined dir to list\n");
        return $self->{test} ? '' : undef ;
      }

    $self->printDebug("Listing HMS dir $args{hmsDir}\n");

    my $run = "fll -RN " ;
    $run .= "-h$args{hmsHost} " if defined $args{hmsHost};
    $run .= "/$args{hmsBase}/" if defined $args{hmsBase} ;
    $run .= $args{hmsDir} ;

    return $run if $self->{test};

    my $result = openPipe 
      (
       workDir => $self->{workDir}, 
       trace => $self->{trace},
       command => $run
      );

    my %ret;
    if (defined $result)
      {
        #foreach file of the component
        foreach my $line (@$result)
          {
            my ($mode,$locker,$size,$time,$name,$rev) = 
              split (/[\s\[\]]+/, $line) ;
            next unless $mode =~ /^000/ ; # directory
            $ret{$name} = {
                           revision => $rev,
                           locker => $locker,
                           time => $time
                          };
          }
      }
    else
      {
        $self->{lastError} = getError ;
        return undef ;
      }
    return \%ret;
  }

1;
