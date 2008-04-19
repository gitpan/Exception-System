#!/usr/bin/perl -al

BEGIN {
    {
	package My::Eval;
	our $n = 0;
	sub test {
	    eval { 1; };
	    $n++;
	}
    }

    {
	package My::DieScalar;
	our $n = 0;
	sub test {
	    eval { die "Message\n"; };
	    if ($@ eq "Message\n") { $n++; }
	}
    }

    {
	package My::DieObject;
	our $n = 0;
	sub test {
	    eval { My::DieObject->throw };
	    if ($@ and $@->isa('My::DieObject')) { $n++; }
	}
	sub throw {
	    my %args = @_;
	    die bless {%args}, shift;
	}
    }
    
    {
	package My::ExceptionBase;
	use lib '../lib';	
	use Exception::Base ':all';
	our $n = 0;
	sub test {
	    try eval { throw 'Exception::Base' => message=>'Message'; };
	    if (catch my $e) {
	        if ($e->isa('Exception::Base') and $e->with('Message')) { $n++; }
	    }
	}
    }

    {
	package My::ExceptionBase1;
	use lib 'lib';	
	use Exception::Base;
	our $n = 0;
	sub test {
	    Exception::Base->try(eval { Exception::Base->throw(message=>'Message', verbosity=>1); });
	    if (Exception::Base->catch(my $e)) {
	        if ($e->isa('Exception::Base') and $e->with('Message')) { $n++; }
	    }
	}
    }

    {
	package My::ExceptionSystem;
	use lib 'lib', '../lib';
	use Exception::Base ':all', 'Exception::System';
	our $n = 0;
	sub test {
	    try eval { throw 'Exception::System' => message=>'Message'; };
	    if (catch my $e) {
	        if ($e->isa('Exception::System') and $e->with('Message')) { $n++; }
	    }
	}
    }

    {
	package My::ExceptionSystem1;
	use lib 'lib', '../lib';
	use Exception::System;
	our $n = 0;
	sub test {
	    Exception::System->try(eval { Exception::System->throw(message=>'Message', verbosity=>1); });
	    if (Exception::System->catch(my $e)) {
	        if ($e->isa('Exception::System') and $e->with('Message')) { $n++; }
	    }
	}
    }

    eval q{
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
    };
}

package main;

use Benchmark ':all';

my %tests = (
    '1_DieScalar'               => sub { My::DieScalar::test; },
    '2_DieObject'               => sub { My::DieObject::test; },
    '3_ExceptionBase'           => sub { My::ExceptionBase::test; },
    '4_ExceptionBase1'          => sub { My::ExceptionBase1::test; },
    '5_ExceptionSystem'         => sub { My::ExceptionSystem::test; },
    '6_ExceptionSystem1'        => sub { My::ExceptionSystem1::test; },
);
$tests{'7_ErrorSystemException'} = sub { My::ErrorSystemException::test; } if eval { Error->VERSION };

my $result = timethese(-1, { %tests });
cmpthese($result);
