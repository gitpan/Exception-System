#!/usr/bin/perl -c

package Exception::System;
use 5.006;
our $VERSION = '0.04';

=head1 NAME

Exception::System - The exception class for system or library calls

=head1 SYNOPSIS

  # Loaded automatically if used as Exception::Base's argument
  use Exception::Base
    'Exception::System',
    'Exception::File' => { isa => 'Exception::System' };

  try Exception::Base eval {
    my $file = "/notfound";
    open FILE, $file
        or throw Exception::File message=>"Can not open file: $file",
                                 file=>$file;
  };
  if (catch Exception::System my $e) {
    if ($e->isa('Exception::File')) { warn "File error:".$e->{errstr}; }
    if ($e->with(errname=>'ENOENT')) { warn "Catched not found error"; }
  }

=head1 DESCRIPTION

This class extends standard exception with handling system or library errors.
The additional fields of the exception object are filled on throw and contain
the error message and error codes.

=cut


use strict;


# Base class
use base 'Exception::Base';


# Use ERRNO hash
use Errno ();


# List of class fields (name => {is=>ro|rw, default=>value})
use constant FIELDS => {
    %{ Exception::Base->FIELDS },     # SUPER::fields
    errstr   => { is => 'ro' },
    errstros => { is => 'ro' },
    errno    => { is => 'ro' },
    errname  => { is => 'ro' },
};


# Map for errno -> errname
my %Errname = map { Errno->$_ => $_ } keys (%!);


# Collect system data
sub _collect_system_data {
    my $self = shift;
    $self->SUPER::_collect_system_data(@_);

    if (not defined $self->{errstr} and
        not defined $self->{errstros} and
        not defined $self->{errname} and
        not defined $self->{errno})
    {
        $self->{errstr} = "$!";   # string context
        $self->{errstros} = $^E;
        $self->{errno} = 0+$!;    # numeric context
        $self->{errname} = $Errname{ $self->{errno} } || '';
    }

    return $self;
}


# Convert an exception to string
sub stringify {
    my $self = shift;
    my $verbosity = shift;
    my $message = shift;

    $verbosity = defined $self->{verbosity} ? $self->{verbosity} : $self->{defaults}->{verbosity}
        if not defined $verbosity;
    $message = defined $self->{message}
               ? ($self->{message} . (defined $self->{errstr} ? ': ' . $self->{errstr} : ''))
               : $self->{defaults}->{message}
        if not defined $message;

    my $string;

    $string = $self->SUPER::stringify($verbosity, $message);

    return $string;
}


1;


=head1 PREREQUISITIES

=over

=item *

L<Exception::Base> >= 0.03

=back

=head1 FIELDS

Class fields are implemented as values of blessed hash.

=over

=item errstr (ro)

Contains the system error string fetched at exception throw.  It is the part
of the string representing the exception object.  It is the same as B<$!>
variable in string context.

  eval { throw Exception::System message=>"Message"; };
  catch Exception::System my $e
    and print $e->{errstr};

=item errstros (ro)

Contains the extended system error string fetched at exception throw.  It is
the same as B<$^E> variable.

  eval { throw Exception::System message=>"Message"; };
  catch Exception::System my $e and $e->{errstros} ne $e->{errstr}
    and print $e->{errstros};

=item errno (ro)

Contains the system error number fetched at exception throw.  It is the same
as B<$!> variable in numeric context.

  eval { throw Exception::System message=>"Message"; };

=item errname (ro)

Contains the system error constant from the system F<error.h> include file.

  eval { throw Exception::System message=>"Message"; };
  catch Exception::System my $e and $e->{errname} eq 'ENOENT'
    and $e->throw;

=back

=head1 METHODS

=over

=item stringify([$I<verbosity>[, $I<message>]])

Returns the string representation of exception object.  The format of output
is "message: error string".

  eval { open F, "/notexisting"; throw Exception::System; };
  print $@->stringify(1);
  print "$@";

=back

=head1 PRIVATE METHODS

=over

=item _collect_system_data

Collect system data and fill the attributes of exception object.  This method
is called automatically if exception if throwed.

See L<Exception::Base>.

=back

=head1 SEE ALSO

L<Exception::Base>.

=head1 BUGS

The module was tested with L<Devel::Cover> and L<Devel::Dprof>.

If you find the bug, please report it.

=head1 AUTHORS

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 LICENSE

Copyright 2007 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
