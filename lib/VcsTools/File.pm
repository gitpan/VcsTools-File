package VcsTools::File;
 
use strict;
use Puppet::Body ;
use Carp ;
use vars qw($VERSION);
use Storable ;
use Sys::Hostname ;
   
use AutoLoader qw/AUTOLOAD/ ;

use base qw/VcsTools::Source/;

$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/;


## Generic part

sub new
  {
    my $type = shift ;
    my %args = @_ ;

    my $self = {};
    $self->{body} = new Puppet::Body(cloth => $self, @_) ;

    if (defined $args{storageArgs})
      {
        # transition code, should be removed sooner or later
        carp "new $type $args{name}: storageArgs is deprecated";
        $self->{storageArgs}=$args{storageArgs};
      }
    elsif (defined $args{storage})
      {
        # we will keep only this parameter
        $self->{storage}= $args{storage};
      }
    else
      {
        croak ("No storage arg passed to $type::$self->{name}\n")
      }
        
    # this will also be deprecated sooner or later
    $self->{usage} = $args{usage} || 'File' ;
    
    bless $self,$type ;
    
    # vcs agent
    if (defined $args{vcsClass})
      {
        $self->{vcsClass}=$args{vcsClass};
        $self->{vcsArgs}=$args{vcsArgs};
      }
    elsif (defined  $args{vcsAgent})
      {
        $self->{vcsAgent}=$args{vcsAgent};
      }
    else
      {
        croak ("No vcsAgent passed to $type::$self->{name}\n")
      }

    $self->{body}->printEvent("Creating File for $args{name}");

    # mandatory parameter
    foreach (qw/name dataScanner workDir/)
      {
        croak ("No $_ passed to $type::$self->{name}\n") unless 
          defined $args{$_};
        $self->{$_} = delete $args{$_} ;
      }

    
    # optional parameter
    foreach (qw/test/)
      {
        $self->{$_} = delete $args{$_} ;
      }

    $self->{trace} = $args{trace} || 0 ;
    
    $self->{workDir} .= '/' unless $self->{workDir} =~ m!/$! ;
 
    $self->init(@_);

    return $self;

  }

#on object destruction, write file info to a file named  file->{name}
#and located in a .tiedHashes directory himself located in the directory
#of the local copy of the working file
sub DESTROY
   {
     my $self = shift;
     $self->check();
     $self->setTiedInfo();
   }


# placed here, it does not conflict with getHistory when the name 
# is truncated by AutoSplit
sub getHistoryHash
  {
    my $self = shift; 
    $self->{dataScanner}->scanHistory($self->getHistory());
  }

1;

__END__


=head1 NAME

VcsTools::File - Perl class to manage a VCS file.

=head1 SYNOPSIS

 my %dbhash; # may be tied to a MLDBM

 use VcsTools::LogParser ;
 use VcsTools::DataSpec::HpTnd qw($description readHook);
 use Puppet::Storage ;
 use VcsTools::HmsAgent ; # could be also RcsAgent 
 my $ds = new VcsTools::DataSpec::HpTnd ;

 my $ds = new VcsTools::LogParser
  (
   description => $description,
   readHook => \&readHook
  ) ;
 
 Puppet::Storage->dbHash(\%dbhash);
 Puppet::Storage->keyRoot('root');

 my $storage= new Puppet::Storage(name => 'dummy.txt') ;

 VcsTools::HmsAgent->hmsBase('test');
 VcsTools::HmsAgent->hmsHost('a_host');
 
 my $agent = VcsTools::HmsAgent->new
  (
   name => 'dummy.txt',
   workDir => cwd().'/'.$dir
  );

 my $vf = new VcsTools::File 
  (
   storage => $storage ,
   vcsAgent => $agent,
   name => 'dummy.txt',
   workDir => $some_dir,
   dataScanner => $ds
  );
 
 $vf -> createArchive();
 $vf -> checkOut(revision => '1.1', lock => 1) ;
 $vf -> archiveFile(info =>{log => 'dummy log for 1.2'});
 $vf -> showDiff(rev1 => '1.1', rev2 => '1.2');
 $vf -> setUpMerge(ancestor => '1.1', below => '1.2', other => '1.1.1.1');


=head1 DESCRIPTION

This class represents a VCS file. It holds all the interfaces to the
"real" world and the history object (See L<VcsTools::History>)).

Firthermore, this class will store the file and archive properties (like
s the file readable, does the archive exists, is it locked...) in a 
L<Storable> file (within a .store directory)

=head1 CAVEATS

The file B<must> contain the C<$Revision: 1.5 $> VCS keyword.

The VCS agent (hmsAgent) creation is clumsy. I should use translucent
attributes or stuff like that like Tom Christiansen described. In
other words, let the user create its agent object and clone it for
File usage. This part is subject to change sooner of later. Only the
constructors should be impacted.

=head1 CONVENTION

The following words may be non ambiguous for native english speakers, but it
is not so with us french people. So I prefer clarify these words:

=over 4

=item *

Log: Refers to the information stored with I<one> version.

=item *

History: Refers to a collection of all logs of all versions stored in
the VCS base.

=back

=head1 Constructor

=head2 new(...)

Will create a new File object.

Parameters are those of L<Puppet::Body/"new(...)"> plus :

=over 4

=item *

dataScanner : L<VcsTools::LogParser> (or equivalent) object reference.

=item *

workDir : Absolute directory where the file is.

=item *

vcsAgent : VCS interface object (e.g. L<VcsTools::HmsAgent>).

=back

=head1 Generic methods

=head2 check()

See L<VcsTools::Source/"check()>

=head1 History handling methods

=head2 createHistory()

Will returns the L<VcsTools::History> object for this file and create it if 
necessary.

=head2 updateHistory()

Extract the history information from the VCS base and update the
VcsTools::History objbect (by calling
L<VcsTools::History/"update(...)">).

This function must be called to re-synchronize your application if the
VCS base was changed by someone else.

=head1 Handling the real file

=head2 createLocalAgent()

Create the file Agent class.

=head2 getTimeStamp()

Returns the last modification time of the file. (See stat function in 
L<perlfunc>)

=head2 edit()

Will launch a window editor though the file agent
(L<VcsTools::FileAgent/"edit()">)

=head2 getRevision()

See L<VcsTools::Source/"getRevision()>

=head2 checkWritable() 

Will return 1 if the file is writable, 0 if not. Will return undef in case
of problems.

=head2 checkExist() 

Will return 1 if the file exists, 0 if not. Will return undef in case
of problems.

=head2 chmodFile(...)

Will change  the file mode to writable or not.

Parameters are :

=over 4

=item *

writable: 1 or 0

=back

Returns 1 if chmod was done and undef in case of problems.

=head2 writeFile(...)

Write the passed content into the actual VCS file..

Parameters are :

=over 4

content: String or hash ref (See L<VcsTools::FileAgent/"writeFile(...)">) 
that will be written.

=back

Returns 1 if the file was written and undef in case of problems.

=head2 writeRevContent(...)

Write the content of a specific version of the VCS file in the passed file 
name. This method is handy when you want to compare several revisions of
a VCS file with a tool which does not support directly your VCS system.

For instance to compare 2 versions of foo.c you may call:

 # creates a v1.2_foo.c file
 $foo->writeRevContent(revision => 1.2); 
 # creates a v1.3_foo.c file
 $foo->writeRevContent(revision => 1.3);

Then you may call xdiff on v1.2_foo.c and v1.3_foo.c.

Parameters are :

=over 4

=item *

revision: writeFile will retrieve this revision of the VCS file and write
it to the passed file name.

=item *

fileName: file name to write to (default to "v<rev>_<VCS_file_name>", e.g.
v1.13_bar.c for version 1.13 of the bar.c VCS file)

=back

Returns the name of the written file if the file was actually written
and undef in case of problems.

=head2 remove()

Unlink the VCS file.

=head1 Handling the VCS part

Before invoking any VCS functions, the File object will check whether
the function can be performed. (For instance, it will not try to perform
a check out if the local file is writable.)

=head2 createVcsAgent()

Create the VCS interface class.

=head2 checkArchive()

Calls checkArchive of the VCS interface
class. (E.g. L<VcsTools::HmsAgent/"checkArchive()">) with the working
revision as the revision parameter..

=head2 changeLock(...)

Delegated to the VCS interface
class. E.g. L<VcsTools::HmsAgent/"changeLock(...)">

=head2 checkOut(...)

Delegated to the VCS interface class. E.g.
L<VcsTools::HmsAgent/"checkOut(...)">

=head2 getContent(...)

Delegated to the VCS interface
class. E.g. L<VcsTools::HmsAgent/"getContent(...)">

=head2 archiveLog(...)

See L<VcsTools::Source/"archiveLog()">

=head2 getHistory()

Delegated to the VCS interface
class. E.g. L<VcsTools::HmsAgent/"getHistory()">

=head2 showDiff(...)

Delegated to the VCS interface
class. E.g. L<VcsTools::HmsAgent/"showDiff(...)">

=head2 archiveFile(...)

Will archive the current file.

Parameters are:

=over 4

=item *

revision: revision number for this new version of the file. Defaults to
a number computed by L<VcsTools::History/"guessNewRev(revision)">,

=item *

info: Hash ref holding relevant informations for this new archive.
(See L<VcsTools::LogParser> for the hash content). Defaults to a 
hash containing 'auto archive' as log information, the current date
and the name of the user performing the archive.

=back

Note that before performing the archive, the program will check the 
timestamp of the archive base and will upload its history informations
if the archive has been changed since the last upload. This way the 
archive number decided by the history object will always be correct.

=head1 TO DO

A merge() method which will find the common ancestor of the passed
revisions, perform a merge using merge(1) and write the result in the
local file.

A patch() method which will report the modif made from one revision to
an other revision on a branch. This can be handy to report a bug fix on
a branch under change control.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(3), Puppet::Any(3), VcsTools::DataSpec::HpTnd(3), 
VcsTools::Version(3), VcsTools::File(3)

=cut



#internal
sub lockIs
  {
    my $self = shift ;
    my $rev = shift ;
    my $locker = shift ;

    $self->{body}->printEvent ("Revision $rev is locked by $locker\n") 
      if defined $rev;

    $self->getRevision() if ($self->{myMode}{exists} and 
                             not defined $self->{myMode}{revision}) ;

    if (defined $rev and $self->{myMode}{exists} and 
        $self->{myMode}{revision} eq $rev)
      {
        #$self->{locked} = $locker ;
        $self->{myMode}{locked} = 1;
        $self->{status}{archive} = 'locked' ;
      }
    else
      {
        #$self->{locked} = 'no';
        $self->{status}{archive} = 'unlocked' ;
        $self->{myMode}{locked} = 0 ;
      }
  }
  

#sub createArchive
#  {
#    my $self = shift ;
#
#    $self->check() unless defined $self->{myMode} ;
#    $self->createVcsAgent() unless defined $self->{vcsAgent} ;
#
#    my $res = $self->{vcsAgent}->create() ;
#    
#    return undef unless defined $res;
#
#    # if success, archive exists, file is read-only, file is unlocked
#    $self->{archive}{exists} = 1 ;
#    $self->{myMode}{revision} = '1.1';
#    $self->{myMode}{writable} = 0 ;
#    $self->{myMode}{locked} = 0 ;
#    $self->{myMode}{mode} = 0444 ;
#    $self->{status}{source}= 'readable' ;
#    $self->{status}{archive} = 'unlocked' ;
#    $self->{myMode}{exists} =1 ;
#    
#    return 1;
#  }


# end Generic part

## Handling the history part

sub createHistory 
  {
    my $self = shift ;

    # handles legacy code 
    my @store = defined $self->{storageArgs} ? 
      (storageArgs => $self->{storageArgs}) :
      (storage => $self->{storage}) ;

    if (not defined $self->{body}->getContent('history'))
      {
        require VcsTools::History ;
        my $how = $self->{trace} ? 'warn' : undef ;
        my $h = new VcsTools::History 
          (
           @store,
           usage => $self->{usage},
           how => $how,
           trace => $self->{trace},
           name => 'history',
           dataScanner => $self->{dataScanner}
          );
        $self->{body}->acquire(body => $h->body(),name => 'history');
      }

    my $h = $self->{body}->getContent('history')->cloth(); 
    #this function return 1 if MySql is used
    
    return $h ;
  }

   
sub updateHistory
  {
    my $self = shift ;
    $self->{body}->printEvent("Checking History informations time\n");
    
    my $h = $self->getHistory();

    $self->check() unless defined $self->{archive}{timeModified} ;

    my $hist = $self->createHistory;

    if (defined $h) 
      {
        $hist->update(history => $h, time => $self->{archive}{timeModified});
      }
    else {$self->{body}->printDebug("Can't get history of $self->{name}\n");}
  }

# end history part

## Handling the real file part

sub createFileAgent
  {
    my $self = shift ;
    warn "createFileAgent is deprecated, please use createLocalAgent";
    $self->createLocalAgent(@_);
  }

sub createLocalAgent
  {
    my $self = shift ;
    unless (defined $self->{localAgent}) 
      {
          require VcsTools::FileAgent ;
          
          # Avoid breaking older versions. To be removed
          $self->{fileAgent} = 
          $self->{localAgent} =  VcsTools::FileAgent -> new 
            (
             name => $self->{name},
             trace => $self->{trace},
             workDir => $self->{workDir}
            );
          
      }
    return $self->{localAgent};
}

sub getTimeStamp
  {
    my $self = shift;
    if ($self->checkExist == 1) 
      {
        my $fullName = $self->createLocalAgent()->makeFullName();
        #get last modif time
        return $self->{localAgent}->stat()->[8];
      }
    else 
      {
        return undef;
      }
  }


sub edit
  {
    my $self = shift ;

    $self->check() unless defined $self->{myMode};

    return undef if 
      defined $self->{myMode}{writable} && not $self->{myMode}{writable};

    $self->createLocalAgent unless defined $self->{localAgent} ;

    $self->{localAgent} -> edit();
  }

sub checkWritable
  {
    my $self = shift ;
    my %args = @_ ;

    $self->{body}->printDebug("checkWritable: Calling stat\n");
    my $res = $self->{localAgent}-> stat();

    if (defined $res)
      {
        $self->{body}->printDebug("Stat result is ".join(' ',@$res)."\n");
        
        $self->{myMode}{mode} = $res->[2] ;
        $self->{myMode}{writable} = $res->[2] & 0200 ? 1 : 0; # octal ;
        $self->{status}{source}= 'writable' if $self->{myMode}{writable} ;
        $self->{body}->printDebug("File mode: $self->{myMode}{mode}, ".
                                  "writable: $self->{myMode}{writable}\n");
        return $self->{myMode}{writable};
      }
    else
      {
        $self->{myMode}{mode} = undef ;
        $self->{myMode}{writable} = undef;
        $self->{status}{source}= 'unknown';
        $self->{body}->printEvent($self->{localAgent}->error()) ;
        return undef;
      }
  }

sub checkExist
  {
    my $self = shift ;
    my %args = @_ ;

    $self->{body}->printDebug("Calling exists\n");
    my $res = $self->{localAgent}-> exist () ;

    if (defined $res)
      {
        if ($res)
          {
            $self->{body}->printDebug("File exists\n");
            $self->{status}{source}='readable' 
              if (defined $self->{status}{source} and 
                  $self->{status}{source} eq "");
          }
        else
          {
            $self->{body}->printEvent("File is missing\n") ;
            $self->{status}{source}="no file";
          }
        $self->{myMode}{exists}=$res;
      }
    else
      {
        $self->{body}->printEvent($self->{localAgent}->error()) ;
      }
 
    # Avoid breaking older versions. To be removed 
    $self->{fileMode} = $self->{myMode} ;

    return $res ;
  }

sub chmodFile
  {
    my $self = shift ;
    my %args = @_ ;

    $self->check() unless defined $self->{myMode}{mode};

    my $writable = $args{writable} ;
    my $mode = $args{mode} ;

    croak "Undefined writable mode when calling chmod on $self->{name}\n" 
      unless (defined $writable or defined $mode);

    $mode = $writable ? 'u+w' : 'u-w' unless defined $mode ;
 
    $self->{body}->printEvent("chmoding $self->{name} with $mode\n");
    
    $self->createLocalAgent unless defined $self->{localAgent} ;
    
    # get file stats
    my $res = $self->{localAgent}-> changeMode(mode => $mode);

    if (defined $res)
      {
        $self->{body}->printDebug("Chmod OK\n");
        $self->checkWritable() ; # get current status
      }
    else 
      {
        $self->{body}->printEvent($self->{localAgent}->error()) ;
      }

    return $res;
  }

sub writeRevContent
  {
    my $self = shift ;
    my %args = @_ ;

    # write a revision of file into another file
    # e.g. write foo version 1.34 to foo_1.34.c
    my $rev   = $args{revision} || 
      croak("no revision passed to writeRevContent");
    my $fname = $args{fileName} || "v${rev}_".$self->{name};

    if ($fname eq $self->{name})
      {
        croak("Cant't clobber file $self->{name} with writeRevContent");
      }

    $self->{body}->
      printEvent("Writing $self->{name} version $rev to file $fname\n");
    my $content = $self->getContent(revision => $args{revision});

    return undef unless (defined $content) ;

    my $res =  $self->doWrite(fileName => $fname, content => $content) ;
    return undef unless defined $res;
    return $fname;
  }

sub writeFile
  {
    my $self = shift ;
    my %args = @_ ;

    croak ("No content passed to $self->{name}->writeFile\n") unless 
      defined $args{content};

    # write a content into file (e.g. into foo.c)
    $self->{body}-> printEvent("Writing new content in  $self->{name}\n");

    return $self->doWrite(fileName => $self->{name},
                          content => $args{content}) ;
  }

# internal
sub doWrite
  {
    my $self = shift ;
    my %args = @_ ;

    # mandatory parameter
    foreach (qw/fileName content/)
      {
        croak ("No $_ passed to $type::$self->{name}\n") unless 
          defined $args{$_};
      }

    if ($args{fileName} eq $self->{name})
      {
        if ($self->{myMode}{exists} and not $self->{myMode}{writable} )
          {
            $self->{body}->
              printEvent("Can't write: $self->{name} if not writable");
            return undef ;
          }
        
        # since we are going to write this non-existent file, it WILL
        # be writable.
        $self->{myMode}{writable} = 1 unless $self->{myMode}{exists} ;
      }

    $self->createLocalAgent() unless defined $self->{localAgent};

    my $res = $self->{localAgent}->writeFile
      (
       name => $args{fileName}, 
       content => $args{content}
      ) ;

    if (defined $res) 
      {
        if ($args{fileName} eq $self->{name})
          {
            #if the file is was written, let's set its timestamp
            #otherwise, nothing ...
            $self->{myMode}{modified} = $self->getTimeStamp();
          }
      }
    else
      {
        $self->{body}->printEvent("Write file $args{name} failed :\n".$self->{localAgent}->error());
      }
    
    return $res ;
  }

sub remove
  {
    my $self = shift;
    $self->createLocalAgent()->remove();
  }

# end real file part

## Handling the archive (VCS) part

sub createVcsAgent
  {
    my $self = shift ;
    my $class = $self->{vcsClass};

    carp ref($self),"::createVcsAgent is deprecated";

    my $file = $class ;
    $file .= '.pm' if $file =~ s!::!/!g ;

    require $file ;

    $self->{body}->printEvent("Creating $class\n");
    $self->{vcsAgent} = $class-> new 
      (
       name => $self->{name},
       workDir => $self->{workDir},
       trace => $self->{trace},
       %{$self->{vcsArgs}}
      );
  }

sub checkArchive
  {
    my $self = shift ;
    my %args = @_ ;
    $self->createVcsAgent() unless defined $self->{vcsAgent} ;
    my $result = $self->{vcsAgent}->
      checkArchive(revision => $self->{myMode}{revision});
    
    if (defined $result)
      {
        my ($rev, $locker,$time) = @$result ;
    
        $self->{body}->printEvent("Archive found") ;
        $self->lockIs($rev,$locker);
        $self->{archive}{exists}=1;
        $self->{archive}{timeModified}=$time;
      }
    else
      {
        my $str = shift ;
        $self->{body}->printEvent("No archive found. ".$self->{vcsAgent}->error()) ;
        $self->{archive}{exists}=0;
        $self->{status}{archive} = "no archive";
      }

    if ($self->{archive}{exists})
      {
        # will update the history if it's obsolete
        $self->updateHistory ;
      }
    
    return $result;
  }

sub changeLock
  {
    my $self = shift ;
    my %args = @_ ;

    # use passed argument
    my $lock = $args{lock} ;
    
    my $rev = defined $args{revision} ? $args{revision} : 
      $self->{myMode}{revision} ;

    unless (defined $lock)
      {
        croak(" $self->{name}::changeLock:  undefined lock mode\n");
      }

    $self->{body}->
      printEvent("Changing lock on $self->{name} rev $rev to $lock\n");
    $self->createVcsAgent() unless defined $self->{vcsAgent} ;

    my $res = $self->{vcsAgent}->changeLock (revision => $rev, lock => $lock );

    if (defined $res)
      {
        $self->{status}{archive}= $lock ? 'locked' : 'unlocked' ;
        $self->{myMode}{locked} = $lock ;
        $self->{body}->printDebug("lock set to $lock OK\n");
      }
    else
      {
        my $str = $self->{vcsAgent}->error();
        $self->{body}->printEvent("changeLock failed :\n$str\n");
      }
    
    return $res ;
  }

sub checkOut
  {
    my $self = shift ;
    my %args = @_ ;

    if ($args{lock} and $self->{myMode}{writable})
      {
        $self->{body}->
          printEvent("$self->{name} checkOut: Can't check out an already writable version\n");
        return undef;
      }

    $self->{body}->
      printEvent("Checking out $self->{name}, revision $args{revision}, lock $args{lock}\n");

    $self->createVcsAgent() unless defined $self->{vcsAgent} ;

    my $crev = $args{revision} || $self->{myMode}{revision} ;
    my $result = $self->{vcsAgent} -> checkOut
      (
       revision => $crev,
       lock => $args{lock}
      ) ;

    if (defined $result)
      {
          $self->{body}->printDebug("checkOut OK\n");
          $self->{myMode}{exists} = 1 ;
          $self->{myMode}{revision} = $args{revision} ;
          $self->{myMode}{writable} = $args{lock} ;
          $self->{status}{source} = $args{lock} ? 'writable' : 'readable' ;
          $self->lockIs($args{revision},'yourself') if $args{lock} ;
          $self->{myMode}{createTime} = $self->getTimeStamp();
          $self->{myMode}{modified} = $self->getTimeStamp();
      }
    else
      {
        my $str = $self->{vcsAgent} ->error();
        $self->{body}->printEvent("Check Out failed : $str\n");
      }

    return $result ;
  }

sub getContent
  {
    my $self = shift ;
    my %args= @_ ;

    unless (defined $args{revision})
      {
        $self->createLocalAgent() unless defined $self->{localAgent};
        my $res = $self->{localAgent}->readFile();
        $self->{body}->
          printEvent("getContent failed: ".$self->{localAgent} ->error())
            unless defined $res;
        return $res ;
      }
    
    $self->check() unless (defined $self->{myMode} and 
                           defined $self->{archive} and 
                           ref $self->{myMode} eq 'HASH' and 
                           scalar keys %{$self->{myMode}} > 0 );

    croak ("$self->{name}: cannot getContent of revision $args{revision} from a non-existing archive\n")
      unless $self->{archive}{exists};

    $self->createVcsAgent() unless defined $self->{vcsAgent} ;
    my $res = $self->{vcsAgent} -> getContent(@_);

    $self->{body}->
      printEvent("getContent $args{revision} failed: ".
                 $self->{vcsAgent} ->error())
        unless defined $res;

    return $res;
  }

    
sub getHistory
  {
    my $self = shift ;
    $self->createVcsAgent() unless defined $self->{vcsAgent} ;
    return $self->{vcsAgent} -> getHistory();
  }
    
sub showDiff
  {
    my $self = shift ;
    $self->createVcsAgent() unless defined $self->{vcsAgent} ;
    $self->{vcsAgent} -> showDiff(@_);
  }


# open correct window
sub archiveFile 
  {
    my $self = shift ;
    my %args = @_ ;

    my $newRev = $self->prepareArchive(@_);

    return undef unless defined $newRev ;

    $self->changeLock(lock => 1) if ($self->{archive}{exists} and 
                                     $self->{myMode}{locked} == 0);

    $self->createVcsAgent() unless defined $self->{vcsAgent} ;
 
    my $infoRef = $args{info} || {};
    $infoRef->{log} = 'auto archive' unless defined $infoRef->{log};
    
    unless (defined $infoRef->{date})
      {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
        $infoRef->{date} = ($year+1900) .'/'.($mon+1)."/$mday $hour:$min:$sec";
      }

    unless (defined $infoRef->{author})
      {
        my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire)
          = getpwuid($<);
        my $fullname = substr($gcos,0,index($gcos,','));
        $infoRef->{author}=$name.'@'.hostname()." ($fullname)";
      }
    
    #create new archive, or add revision ?
    my $res;
    if ($newRev eq '1.1') 
      {
          #create new archive
          $res = $self->{vcsAgent}->create() ;
      }
    else    
      {
          #add new version
          my $logStr= $self->{dataScanner}->buildLogString($infoRef);
          $res = $self->{vcsAgent}->checkIn(revision => $newRev, log => $logStr);
      }
    
    unless (defined $res)
      {
        $self->{body}->printEvent("Can't archive: checkIn failed:".
                                  $self->{vcsAgent}->error() );
        return undef;
      }
   
    $self->createHistory()-> addNewVersion
      (
       revision => $newRev, 
       #after is set to none in case of archive creation
       after => $self->{myMode}{revision}, # can be undef for first archive
       info =>  $infoRef
      ) ;

    # if success, archive exists, file is read-only, file is unlocked
    $self->{myMode}{modified} = $self->getTimeStamp();
    $self->{myMode}{revision} = $newRev;
    $self->{myMode}{writable} = 0 ;
    $self->{myMode}{locked} = 0 ;
    $self->{myMode}{mode} = 0444 ;
    $self->{status}{source}= 'readable' ;
    $self->{status}{archive}= 'unlocked' ;
    $self->{myMode}{exists} =1 ;
    $self->{archive}{exists} = 1 ;
  }

# end VCS part


# internal
# called with named parameters  below ancestor other

sub setUpMerge
  {
    my $self = shift ;
    my %args = @_ ;

    # must check it out
    my $res = $self->checkOut (lock => 1, revision => delete $args{below});

    return undef unless defined $res ;

    $self->{mergeFiles}{below} = $self->{name} ;

    foreach my $key (keys %args)
      {
        my $file = $self->writeRevContent(revision => $args{$key});
        return undef unless defined $file ;
        $self->{mergeFiles}{$key}=$file;
      }

    return $res ;
  }

# internal
sub mergeCleanup
  {
    my $self = shift ;

    $self->createLocalAgent unless defined $self->{localAgent} ;

    foreach my $what (@{$self->{mergeFiles}}{'ancestor','other'})
      {
        $self->{localAgent}->remove (name => $what) ;
      }
  }
          

1;
