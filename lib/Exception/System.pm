#!/usr/bin/perl -c

package Exception::System;
use 5.006;
our $VERSION = 0.09;

=head1 NAME

Exception::System - The exception class for system or library calls

=head1 SYNOPSIS

  # Loaded automatically if used as Exception::Base's argument
  use Exception::Base,
    'Exception::System',
    'Exception::File' => { isa => 'Exception::System' };

  eval {
    my $file = "/notfound";
    open FILE, $file
        or Exception::File->throw(
               message=>"Can not open file: $file",
           );
  };
  if ($@) {
    my $e = Exception::Base->catch;
    if ($e->isa('Exception::File')) { warn "File error:".$e->{errstr}; }
    if ($e->with(errname=>'ENOENT')) { warn "Caught not found error"; }
  }

=head1 DESCRIPTION

This class extends standard L<Exception::Base> with handling system or library
errors.  The additional attributes of the exception object are filled on throw
and contain the error message and error codes.

=for readme stop

=cut


use strict;
use warnings;


# Base class
use base 'Exception::Base';


# Use ERRNO hash
use Errno ();


# List of class attributes (name => {is=>ro|rw, default=>value})
use constant ATTRS => {
    %{ Exception::Base->ATTRS },     # SUPER::ATTRS
    message  => { is => 'rw', default => 'Unknown system exception' },
    errstr   => { is => 'ro' },
    errstros => { is => 'ro' },
    errno    => { is => 'ro' },
    errname  => { is => 'ro' },
};


# Map for errno -> errname (choose the shortest errname string for the same errno number)
my %Errname = map { Errno->$_ => $_ }
              sort { length $b <=> length $a }
              sort
              keys (%!);


# Collect system data
sub _collect_system_data {
    my $self = shift;

    $self->{errstr} = "$!";   # string context
    $self->{errstros} = $^E;
    $self->{errno} = 0+$!;    # numeric context
    $self->{errname} = $Errname{ $self->{errno} } || '';

    return $self->SUPER::_collect_system_data(@_);
}


# Convert an exception to string
sub stringify {
    my ($self, $verbosity, $message) = @_;

    # the argument overrides the attribute
    $message = $self->{message} unless defined $message;

    my $is_message = defined $message && $message ne '';
    my $is_errstr = $self->{errstr};
    if ($is_message or $is_errstr) {
        $message = ($is_message ? $message : '')
                 . ($is_message && $is_errstr ? ': ' : '')
                 . ($is_errstr ? $self->{errstr} : '');
    }
    else {
        $message = $self->{defaults}->{message};
    }

    return $self->SUPER::stringify($verbosity, $message);
}


# Stringify for overloaded operator. The same as SUPER but Perl needs it here.
sub __stringify {
    return $_[0]->stringify;
}


# Module initialization
sub __init {
    __PACKAGE__->_make_accessors;
}


__init;


1;


__END__

=head1 BASE CLASSES

=over

=item *

L<Exception::Base>

=back

=head1 ATTRIBUTES

Class attributes are implemented as values of blessed hash.  The attributes of
base class are inherited.  See L<Exception::Base> to see theirs description.

=over

=item errstr (ro)

Contains the system error string fetched at exception throw.  It is the part
of the string representing the exception object.  It is the same as B<$!>
variable in string context.

  eval { Exception::System->throw( message=>"Message" ); };
  my $e = Exception::Base->catch
    and print $e->{errstr};

=item errstros (ro)

Contains the extended system error string fetched at exception throw.  It is
the same as B<$^E> variable.

  eval { Exception::System->throw( message=>"Message" ); };
  if ($@) {
    my $e = Exception::Base->catch;
    if ($e->{errstros} ne $e->{errstr}) {
      print $e->{errstros};
    }
  }

=item errno (ro)

Contains the system error number fetched at exception throw.  It is the same
as B<$!> variable in numeric context.

  use Errno ();
  eval { Exception::System->throw( message=>"Message" ); };
  if ($@) {
    my $e = Exception::Base->catch;
    if ($e->{errno} == &Errno::ENOENT) {
      warn "Not found";
    }
  }

=item errname (ro)

Contains the system error constant from the system F<error.h> include file.

  eval { Exception::System->throw( message=>"Message" ); };
  my $e = Exception::Base->catch
    and $e->{errname} eq 'ENOENT'
    and $e->throw;

=back

=head1 METHODS

=over

=item stringify([$I<verbosity>[, $I<message>]])

Returns the string representation of exception object.  The format of output
is "I<message>: I<errstr>".

  eval { open F, "/notexisting" or Exception::System->throw; };
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

If you find the bug, please report it.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 LICENSE

Copyright (C) 2007, 2008 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
