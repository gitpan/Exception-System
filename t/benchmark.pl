#!/usr/bin/perl -al

package My::Eval;
our $n = 0;
sub test {
    eval { 1; };
    $n++;
}


package My::DieScalar;
our $n = 0;
sub test {
    eval { die "Message\n"; };
    if ($@ eq "Message\n") { $n++; }
}


package My::DieObject;
our $n = 0;
sub test {
    eval { throw My::DieObject };
    if ($@ and $@->isa('My::DieObject')) { $n++; }
}
sub throw {
    my %args = @_;
    die bless {%args}, shift;
}


package My::ExceptionBase;
use lib '../lib';	
use Exception::Base;
our $n = 0;
sub test {
    try Exception::Base eval { throw Exception::Base message=>'Message'; };
    if (catch Exception::Base my $e) {
        if ($e->isa('Exception::Base') and $e->with('Message')) { $n++; }
    }
}


package My::ExceptionBase1;
use lib 'lib';	
use Exception::Base;
our $n = 0;
sub test {
    try Exception::Base eval { throw Exception::Base message=>'Message', verbosity=>1; };
    if (catch Exception::Base my $e) {
        if ($e->isa('Exception::Base') and $e->with('Message')) { $n++; }
    }
}


package My::ExceptionSystem;
use lib 'lib', '../lib';
use Exception::System;
our $n = 0;
sub test {
    try Exception::System eval { throw Exception::System message=>'Message'; };
    if (catch Exception::System my $e) {
        if ($e->isa('Exception::System') and $e->with('Message')) { $n++; }
    }
}


package My::ExceptionSystem1;
use lib 'lib', '../lib';
use Exception::System;
our $n = 0;
sub test {
    try Exception::System eval { throw Exception::System message=>'Message', verbosity=>1; };
    if (catch Exception::System my $e) {
        if ($e->isa('Exception::System') and $e->with('Message')) { $n++; }
    }
}


package My::ErrorSystemException;
use Error qw(:try);
use Error::SystemException;
our $n = 0;
sub test {
    try {
        throw Error::SystemException('Message');
    }
    catch Error with {
        my $e = shift;
        if ($e->text eq 'Message') { $n++; }
    };
}


package main;

use Benchmark;

timethese(-1, {
    '1_DieScalar'               => sub { My::DieScalar::test; },
    '2_DieObject'               => sub { My::DieObject::test; },
    '3_ExceptionBase'           => sub { My::ExceptionBase::test; },
    '4_ExceptionBase1'          => sub { My::ExceptionBase1::test; },
    '5_ExceptionSystem'         => sub { My::ExceptionSystem::test; },
    '6_ExceptionSystem1'        => sub { My::ExceptionSystem1::test; },
    '7_ErrorSystemException'    => sub { My::ErrorSystemException::test; },
});

