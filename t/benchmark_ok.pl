#!/usr/bin/perl -al

use lib 'lib', '../lib';

BEGIN {
    package My::Common;
    *throw_something = $0 =~ /_ok/ ? sub () { 0 } : sub () { 1 };
}

{
    package My::EvalDieScalar;
    sub test {
        eval {
            die 'Message' if My::Common::throw_something;
        };
        if ($@ =~ /^Message/) {
            1;
        }
    }
}

{
    package My::EvalDieObject;
    sub test {
        eval {
             My::EvalDieObject->throw if My::Common::throw_something;
        };
        if ($@) {
            my $e = $@;
            if (ref $e and $e->isa('My::EvalDieObject')) {
                1;
            }
        }
    }
    sub throw {
        my %args = @_;
        die bless {%args}, shift;
    }
}

{
    package My::ExceptionEval;
    use Exception::Base ':all', 'Exception::My';
    sub test {
        eval {
            Exception::My->throw(message=>'Message') if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::My') and $e->with('Message')) {
                1;
            }
        }
    }
}

{
    package My::ExceptionTry;
    use Exception::Base ':all', 'Exception::My';
    sub test {
        try eval {
            Exception::My->throw(message=>'Message') if My::Common::throw_something;
        };
        if (catch my $e) {
            if ($e->isa('Exception::My') and $e->with('Message')) {
                1;
            }
        }
    }
}

{
    package My::ExceptionSystemEval;
    use Exception::Base ':all', 'Exception::System';
    sub test {
        eval {
            Exception::System->throw(message=>'Message') if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::System') and $e->with('Message')) {
                1;
            }
        }
    }
}

{
    package My::ExceptionSystemTry;
    use Exception::Base ':all', 'Exception::System';
    sub test {
        try eval {
            Exception::System->throw(message=>'Message') if My::Common::throw_something;
        };
        if (catch my $e) {
            if ($e->isa('Exception::System') and $e->with('Message')) {
                1;
            }
        }
    }
}

{
    package My::Exception1Eval;
    use Exception::Base ':all', 'Exception::My';
    sub test {
        eval {
            Exception::My->throw(message=>'Message', verbosity=>1) if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::My') and $e->with('Message')) {
                1;
            }
        }
    }
}

{
    package My::Exception1Try;
    use Exception::Base ':all', 'Exception::My';
    sub test {
        try eval {
            Exception::My->throw(message=>'Message', verbosity=>1) if My::Common::throw_something;
        };
        if (catch my $e) {
            if ($e->isa('Exception::My') and $e->with('Message')) {
                1;
            }
        }
    }
}

{
    package My::ExceptionSystem1Eval;
    use Exception::Base ':all', 'Exception::System';
    sub test {
        eval {
            Exception::System->throw(message=>'Message', verbosity=>1) if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::System') and $e->with('Message')) {
                1;
            }
        }
    }
}

{
    package My::ExceptionSystem1Try;
    use Exception::Base ':all', 'Exception::System';
    sub test {
        try eval {
            Exception::System->throw(message=>'Message', verbosity=>1) if My::Common::throw_something;
        };
        if (catch my $e) {
            if ($e->isa('Exception::System') and $e->with('Message')) {
                1;
            }
        }
    }
}

eval q{
    package My::Error;
    use Error qw(:try);
    sub test {
        try {
            Error::Simple->throw('Message') if My::Common::throw_something;
        }
        Error->catch(with {
            my $e = $_[0];
            if ($e->text eq 'Message') {
                1;
            }
        });
    }
};

eval q{
    package My::ErrorSystem;
    use Error qw(:try);
    use Error::SystemException;
    sub test {
        try {
            Error::SystemException->throw('Message') if My::Common::throw_something;
        }
        Error->catch(with {
            my $e = $_[0];
            if ($e->text eq 'Message') {
                1;
            }
        });
    }
};


package main;

use Benchmark ':all';

my %tests = (
    '01_EvalDieScalar'             => sub { My::EvalDieScalar->test },
    '02_EvalDieObject'             => sub { My::EvalDieObject->test },
    '03_ExceptionEval'             => sub { My::ExceptionEval->test },
    '04_ExceptionTry'              => sub { My::ExceptionTry->test },
    '05_ExceptionSystemEval'       => sub { My::ExceptionSystemEval->test },
    '06_ExceptionSystemTry'        => sub { My::ExceptionSystemTry->test },
    '07_Exception1Eval'            => sub { My::Exception1Eval->test },
    '08_Exception1Try'             => sub { My::Exception1Try->test },
    '09_ExceptionSystem1Eval'      => sub { My::ExceptionSystem1Eval->test },
    '10_ExceptionSystem1Try'       => sub { My::ExceptionSystem1Try->test },
);
$tests{'11_Error'}                  = sub { My::Error->test }                if eval { Error->VERSION };
$tests{'12_ErrorSystem'}            = sub { My::ErrorSystem->test }          if eval { Error::SystemException->can('new') };

print "Benchmark for ", (My::Common::throw_something ? "FAIL" : "OK"), "\n";
#foreach (keys %tests) {
#    printf "%s = %d\n", $_, $tests{$_}->();
#}
my $result = timethese($ARGV[0] || -1, { %tests });
cmpthese($result);
