package VcsTools::Source ;
 
use strict;
use Puppet::Body ;
use Carp ;
use vars qw($VERSION);
use Storable ;
use Sys::Hostname ;
   
use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;


## generic methods

sub init
  {
    my $self = shift;
    my %args = @_;

    ##update the local informations about the file
    $self->getTiedInfo();    

    if ($self->createLocalAgent()->exist() == 1)
      {
        $self->{myMode}{modified} = $self->getTimeStamp() 
          unless defined $self->{myMode}{modified};
      }
    else
      {
        delete $self->{myMode}{modified} if defined $self->{myMode}{modified};
        undef $self->{myMode}{writable};
      }

    #add the history to the contents if it is defined
    if (defined $args{history})
      {
        $self->{history} = $args{history};
        $self->{body}->acquire(body => $self->{history}->body(),
                               name => 'history');
      }
  }

sub error
  {
     my $self=shift ;
     return $self->{lastError} ;
  }

1;

__END__


=head1 NAME

VcsTools::Source - Perl base class for some VcsTools components

=head1 SYNOPSIS

No synopsis given. Virtual class.

=head1 DESCRIPTION

This class is just a way not to duplicate functions.

=head1 Generic methods

=head2 check()

Checks r/w permission of the local file, the revision of the local file 
and lock state of the file.

The file must contain the C<$Revision: 1.1 $> keyword.

=head2 getRevision()

Will return the revision of the local file. Will return undef in case
of problems.

=head1 Handling the VCS part

=head2 archiveLog(...)

Will modify the log (not the file) of a specified revision of the file in
the VCS base. 

Parameters are :

=over 4

=item *

info: info hash that contains the new informations to update the log in the
VCS base

=item *

revision: revision number of the log to update.

=back

Returns an array ref containing the output of the VCS command in case
of success, undef in case of problems.

=cut

# internal
# used to check between the stored status and myMode which are
# modified by the object method. and the actual status of the physical file

sub checkError
  {
    my $self = shift ;
    my %args = @_ ;
    
    my %status = %{$self->{status}};
    my %fmode  = %{$self->{myMode}} ;
    
    $self->check(@_) ;
    
    my $ok =1 ;
    foreach my $key (keys %status)
      {
        my $tmp = $status{$key} eq $self->{status}{$key};
        $self->{body}->printDebug("status $key pb, expected $status{$key} ".
                                  "got $self->{status}{$key}")
          unless $tmp ;
        $ok&=$tmp;
      }
    
    foreach  my $key (keys %fmode)
      {
        next if $key eq 'mode'; # to difficult to predict
        my $tmp = $fmode{$key} eq $self->{myMode}{$key};
        $self->{body}->printDebug("mode $key pb expected $fmode{$key}".
                                  "got $self->{myMode}{$key}") 
          unless $tmp ;
        $ok&=$tmp;
      }
    
    return $ok ;
  }


# check existence of  file and its lock state
sub check
  {
    my $self = shift ;
    my %args = @_ ;

    $self->createLocalAgent unless defined $self->{localAgent} ;

    $self->{body}->printEvent("Checking local copy\n");

    $self->{status}{source}="";
    $self->{status}{archive}="";

    $self->checkExist ();
    $self->checkArchive ();
    
    # file exists -> check writable
    # file archived and exist -> check revision

    # get file stats
    $self->checkWritable() if $self->{myMode}{exists} ;
    
    $self->getRevision  ()
      if $self->{archive}{exists} and $self->{myMode}{exists} ;

    return $self->{myMode} ;
  }

sub getModeRef
  {
    return shift->{myMode} ;
  }

sub getStatusRef
  {
    return shift->{status} ;
  }

sub getArchiveRef
  {
    return shift->{archive} ;
  }


# end Generic part

## Handling the history part

sub historyRef 
  {
    my $self = shift ;
    #BOB
    $self->createHistory;
    #return $self->{body}->getContent('history')->cloth();
  }

# end history part

## Handling the real file part

sub getRevision
  {
    my $self = shift ;
    my %args = @_ ;

    $self->{body}->printDebug("Extracting Rev from local source\n");
    my $res = $self->{localAgent}-> getRevision();

    if (defined $res and $res ne '0')
      {
        $self->{body}->printEvent("Found revision $res\n");
        $self->{myMode}{revision} = $res ;
      }
    else
      {
        $self->{body}->printEvent($self->{localAgent}->error()) ;
        # this is a major error where VCS is concerned.
        croak "Can't extract revision from file $self->{name}. Is \$Revision\$ missing?"
      }

    return $res ;
  }

## Handling the archive part

sub archiveLog
  {
    my $self = shift ;
    my %args = @_ ;

    foreach (qw/revision info/)
      {
        die "No $_ passed to $self->{name}::archiveLog\n" unless 
          defined $args{$_};
      }

    $self->{body}->printEvent("Archiving a log for revision $args{revision}");
    
    $self->createVcsAgent() unless defined $self->{vcsAgent} ;
    
    my $h = $self->createHistory();

    # check that the revision actually exists
    my $versionObj = $h->getVersionObj($args{revision}) ;
    
    unless (defined $versionObj)
      {
        $self->printEvent("Can't archive log: unknown revision $args{revision}\n");
        return undef ;
      }

    # create suitable string for archive
    my $logStr= $self->{dataScanner}->buildLogString($args{info});

    # archive the info in the VCS system
    my $res = $self->{vcsAgent} -> archiveLog 
      (
       revision => $args{revision},
       log => $logStr,
       state => $args{info}{state}
      );

    # update the History and Version object
    if (defined $res)
      {
        $versionObj->update(info => $args{info});
      }
    else
      {
        $self->{body}->printEvent("archiveLog failed: ".$self->{vcsAgent}->error()) ;
        return undef ;
      }
  }

# internal    
sub prepareArchive
  {
    my $self = shift ;
    my %args = @_ ;

    # always check if the archive has not been changed by someone else.
    #if ( defined $self->{myMode}) {$self->checkArchive();} 
    #else {$self->check() ;}
    $self->check();
    unless ($self->{myMode}{writable})
      {
        $self->{body}->printEvent("Can't archive non writable source\n");
         return undef;
      }

    unless ($self->{archive}{exists})
      {
        return '1.1';
      }
    
    my $history = $self->createHistory() ;

    my $newRev = $args{revision} ||
      $history->guessNewRev($self->{myMode}{revision}) ;

    unless (defined $newRev)
      {
        $self->{body}->printEvent("Can't archive: can't guess new rev\n");
        return undef ;
      }

    $self->{body}->printEvent
      (
       "Archiving file from version ".$self->{myMode}{revision}.
       " to $newRev\n"
      );

    return $newRev;
  }

#####the following methods manage permanent data

# See perl module Class::ERoot if it gets more complex.

# Should use Storable instead.

my @permanent = qw/myMode status archive/ ;

sub setTiedInfo
  {
    my $self = shift;
    
    # management of the directory containing the permanent data :
    #create the save directory, save current dir
    #move to save directory, save data into the tied hash
    #and go back to current directory
   
    warn "Saving permanent data for $self->{name}\n";

    #no more ending slash !
    $self->{workDir} =~ s/\/$//;
    my $saveDir = $self->{workDir}.'/.store/'; 
    mkdir $saveDir,0700 unless -e $saveDir and -d $saveDir;

    #file and tied hash creation
    my $file = $saveDir.$self->{name};
    unlink($file) if -r $file ;
    my %hash;
    
    foreach my $what (@permanent)
      {
        $hash{$what} = $self->{$what} if 
          (
           defined $self->{$what} and 
           ref $self->{$what} eq 'HASH' and 
           scalar keys %{$self->{$what}} > 0
          );        
      }
    store \%hash, $file ;
  }

sub getTiedInfo
  {
    my $self = shift;
    
    #no more ending slash !
    $self->{workDir} =~ s/\/$//;
    my $file = $self->{workDir}.'/.store/'.$self->{name}; 

    if (-e $file and -r $file)
      {
        my $h = retrieve($file) ;

        #update volatile data using permanent ones
        foreach my $what (@permanent)
          {
            $self->{$what} = $h->{$what} if (defined $h->{$what});
          }
      }
  }

1;
