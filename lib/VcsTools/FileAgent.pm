package VcsTools::FileAgent ;

use VcsTools::Process;
use Carp;

use strict;

use vars qw($VERSION);
use AutoLoader qw/AUTOLOAD/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

sub new
  {
    my $type = shift ;
    my %args = @_ ;
    my $self= {lastError => ''} ;

    # mandatory parameter
    foreach (qw/name workDir/)
      {
        die "No $_ passed to $type $self->{name}\n" unless defined $args{$_};
        $self->{$_} = delete $args{$_} ;
      }

    $self->{trace} = $args{trace} || 0 ;
    $self->{workDir} .= '/' unless $self->{workDir} =~ m!/$! ;

    die "directory $self->{workDir} does not exist\n" 
      unless -d $self->{workDir};
    
    my $fullName = "/$self->{workDir}/$self->{name}" ;
    $fullName =~ s!//!/!g ;
    $self->{fullName}=$fullName ;

    bless $self,$type ;
  }


1;

__END__


=head1 NAME

VcsTools::FileAgent - Perl class to handle a file

=head1 SYNOPSIS

 my $agent = "VcsTools::FileAgent" ;

 my $fa = new $agent(name => 'test.txt',
                     workDir => $ENV{'PWD'}.'/'.$dtest);


 $fa->writeFile(content => "dummy content\n") ;

 $fa->readFile() ;

 $fa->stat() ;

=head1 DESCRIPTION

This class is used as a file agent to perform some operation such as
pipe, stat, read, write. This class will take care of going in and out
of the directory where the file is and will perform basic error handling.

This class will use L<VcsTools::Process> to launch child processes.

Note that one FileAgent class must be created for one file.

=head1 Constructor

=head2 new(...)

Creates a new  class. 

Parameters are :

=over 4

=item *

name: file name (mandatory)

=item *

workDir: local directory where the file is.

=item *

trace: If set to 1, debug information are printed.

=back

Will create a FileAgent for file 'a_name' in directory 'workDir'.

=head1 Methods

=head2 edit()

Will run a non-blocking gnuclient session to edit the file.

=head2 merge(...)

Will connect to xemacs (with gnudoit) and will run a non-blocking ediff 
session. See the ediff documentation.

Parameters are :

=over 4

=item *

ancestor: the file name which contains the ancestor of the 2 files to merge

=item *

below:  the file name which contains one of the revision to merge.

=item *

other: the file name which contains the other revision to merge.

=back

Returns 1 when the ediff is launched. Returns undef in case of problems.
Note that merge will return once ediff is luanched, not when the ediff
session is done.

=head2 writeFile(...)

Will write a string (or an array joined with "\n") into the file.

parameters are :

=over 4

=item *

content: string | ref_to_string_array

=item *

name: optional file name that will be written to (defaults to the name
passed to the constructor).

=back

=head2 readFile()

Will read the content of the file. Returns a ref to an array containing
the file lines

=head2 getRevision()

Will read the content of the file and return the revision number..

=head2 stat()

Will perform a stat (see perlfunc(3)) on the file and return the stat
array.

=head2 exist()

Will return '1' or '0' if the file exists or not. ('C<-e>' test). 

=head2 chmod(...)

Will perform a chmod (see perlfunc(3)) on the file.

Parameters are :

=over 4

=item *

mode: 0xxx mode

=back

=head2 remove()

Will unlink (see perlfunc(3))  the file .

parameters are :

=over 4

=item *

name: optional file name that will be written to (defaults to the name
passed to the constructor).

=back

=head1 Error handling

In case of problems, all function will return undef.

In this case of problem, you can call the error() method to get a string
describing the problem of the B<last> command.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), VcsTools::Process(3)

=cut

sub edit 
  {
    my $self = shift ;

    my $command =  "gnuclient -q $self->{name}";
    return mySystem
      (
       command => $command, 
       trace => $self->{trace},
       workDir => $self->{workDir}
      );
  }

sub merge
  {
    my $self = shift ;
    my %args = @_ ;

    my @files = ($args{below}, $args{other}, $args{ancestor}) ;
    map($_ = $self->{workDir}.$_,@files);
    my $lisp = '(ediff-merge-files-with-ancestor "'. join('" "',@files) . '")';
    my $command = "gnudoit -q '$lisp'" ;

    return mySystem
      (
       command => $command, 
       trace => $self->{trace},
       workDir => $self->{workDir}
      );

    # run xemacs `ediff-merge-files-with-ancestor',
    # arguments: (file-A file-B file-ancestor &optional startup-hooks)
  }

sub makeFullName
  {
    my $self = shift ;
    my %args = @_ ;

    my $f ;
    if (defined $args{fullName}) {$f = $args{fullName} ;} 
    elsif (defined $args{name}) {$f = $self->{workDir}.$args{name} ;} 
    else {$f = $self->{fullName}};

    return $f ;
  }

sub error
  {
     my $self=shift ;
     return $self->{lastError} ;
  }

sub writeFile
  {
    my $self = shift ;
    my %args = @_ ;

    my $f = $self->makeFullName(@_);

    warn "Writing in file $f\n" if $self->{trace};

    unless (defined $args{content} )
      {
        croak("No content specified to write file $f");
      }
          
    unless (open(FOUT,">$f") )
      {
        $self->{lastError}="open >$f failed:$!";
        return undef;
      }

    if (ref($args{content}) eq 'ARRAY')
      {
        print FOUT map {$_ .= "\n" unless /\n$/}  @{$args{content}} ;
      }
    else
      {
        print FOUT $args{content} ;        
      }

    close(FOUT) ;
    return 1;
  }

sub readFile
  {
    my $self = shift ;
    my %args = @_ ;

    my $f = $self->makeFullName(@_);

    warn "Reading file $f\n" if $self->{trace};

    unless (open(FIN,"$f") )
      {
        $self->{lastError}="open $f failed:$!";
        return undef;
      }

    my @str = <FIN> ;
    close(FIN) ;
    return \@str ;
  }

sub getRevision
  {
    my $self = shift ;
    my %args = @_ ;

    warn "Extracting Revision from $self->{name}\n" if $self->{trace};
    my $ref = $self-> readFile(@_);

    return undef unless defined $ref;

    my $localRev ;
    foreach  (@$ref)
      {
        last if (($localRev)= /\$Revision: ([\d\.]+)/) ;
      }

    return $localRev ;
  }
 
sub stat
  {
    my $self = shift ;
    my %args = @_ ;

    my $f = $self->makeFullName(@_);
    warn "Stat on file $f\n" if $self->{trace};
    my @res = CORE::stat($f) ;
    if (scalar @res)
      {
        return \@res ;
      }
    else
      {
        $self->{lastError}="$f stat failed: $!" ;
        return undef;
      }
  }

sub exist
  {
    my $self = shift ;
    my %args = @_ ;

    my $f = $self->makeFullName(@_);
    warn "Checking if file $f exists\n" if $self->{trace};

    if (-d $self->{workDir}) {return -e $f ? 1 : 0 ;} 
    else 
      {
        $self->{lastError}="Can't read directory $self->{workDir}\n" ;
        warn $self->{lastError} if $self->{trace};
        return undef ;
      }
  }

sub chmod
  {
    my $self = shift ;
    my %args = @_ ;

    my $f = $self->makeFullName(@_);

    unless (defined $args{mode} )
      {
        croak ("No mode specified to chmod file $f\n");
      }
          
    my $mode = $args{mode} ;
    warn "chmod $mode on file $f\n" if $self->{trace};

    my $res = CORE::chmod $mode, $f ;
    if ($res)
      {
        return 1;
      }
    else
      {
        $self->{lastError}="$f chmod failed: $!\n" ;
        return undef;
      }
  }

sub remove
  {
    my $self = shift ;
    my %args = @_ ;

    my $f = $self->makeFullName(@_);

    warn "Removing file $f\n" if $self->{trace};
    unless (unlink($f) )
      {
        $self->{lastError}="remove $f failed:$!";
        return undef;
      }

    return 1;
  }
