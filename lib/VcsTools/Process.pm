package VcsTools::Process ;

use strict;

use vars qw($VERSION $error @EXPORT %expect);
use IPC::Open3;
use FileHandle;
use Cwd;
use Carp;
use base 'Exporter';

use AutoLoader qw/AUTOLOAD/ ;
@EXPORT=qw(getError mySystem openPipe pipeIn);

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

%expect = ( 0 => 1, 256 => 0 ) ; # default ksh result interpretation

1;

__END__

=head1 NAME

VcsTools::Process - Perl functions to handle child process (blocking mode)

=head1 SYNOPSIS

 my $res = openPipe 
  (
   command => 'll',
   trace => $trace
  ) ;

 $res = pipeIn (command => 'bc',
               trace => $trace,
               input => "3+4+2\nquit\n"
              );

 $res = mySystem
   (
    command => 'echo >/dev/console',
    trace => $trace,
   );

=head1 DESCRIPTION

This package provides functions which are the standard perl functions
(system, open, and open2) with some sugar coating to avoid duplicated code.

=head1 Common parameters

The functions mySystem, openPipe and pipeIn accepts these parameters:

=over 4

=item *

command: the command to run

=item *

trace: If set to 1, the command will be printed on STDERR before execution.

=item *

expect: hash ref specifying how the process exit code must be interpreted.
Defaults to ( 0 => 1, 255 => 0 ).

=item *

workDir: where to run the command (defaults to the current
directory). If specified all functions will perform a chdir to
'workDir' before executing the command and will chdir back before
returning.

=back

=head1 Error checking

In case of errors all functions returns undef. In this case you can 
get the error cause by calling the getError function.

=head1 Functions

=head2 mySystem(...)

Will run a system() call. Returns 1 in case of succes, undef in case of
problems.

=head2 openPipe(...)

Will open a pipe on command and read its STDOUT. Returns an array ref 
in case of succes, undef in case of problems.

The array will contain chomped lines of the STDOUT of the command.

=head2 pipeIn(...)

Will open a pipe on the STDIN and STDOUT of command (see open2), send the
content of the 'input' parameter to the process and read its STDOUT.

Returns an array ref in case of succes, undef in case of problems.

The array will contain chomped lines of the STDOUT of the command.

Parameters are:

=over 4

=item *

input: string to send to the command

=back

=head2 getError()

Return a string containing the error message of the last command which had
some problem. It works a bit like the errno variable.

=head1 AUTHOR

Dominique Dumont, Dominique_Dumont@grenoble.hp.com

Copyright (c) 1998-1999 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1)

=cut

# 

sub getError
{
  my $self = shift ;
  return $error ;
}

sub mySystem
  {
    my %args = @_ ;

    my $dir = cwd() ;

    if (defined $args{workDir} and not chdir ($args{workDir}))
      {
        $error = "Can't cd to $args{workDir}:$!";
        return undef ;
      } 

    warn "running $args{command}\n" if $args{trace};

    my $ret = system($args{command}) ;
    
    my $res = defined $args{expect} ? $args{expect}{$ret} : $expect{$ret} ;
    warn "shell returned $ret, result is $res\n" if $args{trace};

    chdir ($dir) if defined $args{workDir} ;

    if (defined $res and $res)
      {
        return 1;
      } 
    else
      {
        $error = "$args{command} failed:$!";
        return undef ;
      } 
  }

sub openPipe
  {
    my %args = @_ ;

    my $dir = cwd() ;

    if (defined $args{workDir} and not chdir ($args{workDir}))
      {
        $error="Can't cd to $args{workDir}:$!";
        return undef;
      } 

    warn "running $args{command} | \n" if $args{trace};
    my $fh = new FileHandle;
    $fh->open ($args{command}.' |')
      or croak "can't open pipe $args{command}: $!\n";
    my @output = <$fh>;
    $fh->close;
    
    chdir ($dir)  if defined $args{workDir};

    my $res = defined $args{expect} ? $args{expect}{$?} : $expect{$?} ;
    warn "shell returned $?, result is $res\n" if $args{trace};

    if  (defined $res and $res)
      {
        chomp @output ;
        return \@output;
      }
    else
      {
        $error = "@output";
        return undef ;
      } ;
  }

sub pipeIn
  {
    my %args = @_ ;

    my $dir = cwd() ;

    if (defined $args{workDir} and not chdir ($args{workDir}))
      {
        $error="Can't cd to $args{workDir}:$!";
        return undef;
      } 
    
    croak "No input for pipeIn\n" unless defined $args{'input'};
    
    warn "Pipe in $args{command} \nInput: \n",$args{'input'} 
    if $args{trace};

    my $pid = open3(\*WTR,\*RDR,'',"$args{command}") 
      or croak "can't do open3 on $args{command}\n";
    print WTR $args{input} ;

    my @output = <RDR> ;
    chomp @output ;

    close (RDR);
    close (WTR);

    my $res = defined $args{expect} ? $args{expect}{$?} : $expect{$?} ;
    warn "shell returned $?, result is $res\n" if $args{trace};

    chdir ($dir)  if defined $args{workDir};

    if  (defined $res and $res)
      {
        chomp @output ;
        return \@output;
      }
    else
      {
        $error = "@output";
        return undef ;
      } ;
  }

1;
