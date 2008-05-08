package Exception::SystemTest;

use strict;
use warnings;

use base 'Test::Unit::TestCase';

use Exception::System;

use Errno ();

our $ENOENT;

sub set_up {
    $! = Errno::ENOENT;
    $ENOENT = $!;
    $! = 0;
}

sub test___isa {
    my $self = shift;
    my $obj = Exception::System->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa("Exception::System"), '$obj->isa("Exception::System")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
}

sub test_attribute {
    my $self = shift;
    local $!;
    my $obj = Exception::System->new(message=>'Message');
    $self->assert_equals('Message', $obj->{message});
    $self->assert_equals(0, $obj->{errno});
}

sub test_accessor {
    my $self = shift;
    local $!;
    my $obj = Exception::System->new(message=>'Message');
    $self->assert_equals('Message', $obj->message);
    $self->assert_equals('New message', $obj->message = 'New message');
    $self->assert_equals('New message', $obj->message);
    $self->assert_equals(0, $obj->errno);
    eval { $self->assert_equals(0, $obj->errno = 123) };
    $self->assert_matches(qr/modify non-lvalue subroutine call/, $@);
}

sub test_collect_system_data {
    my $self = shift;
    
    eval {
        eval { 1; };

        my $obj = Exception::System->new(message=>'Collect');
        $self->assert_not_null($obj);
        $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
        $self->assert_equals('Collect', $obj->{message});
        $self->assert_not_null($obj->{errstr});
        $self->assert_not_null($obj->{errstros});
        $self->assert_not_null($obj->{errname});
        $self->assert_not_null($obj->{errno});

        $obj->{errno} = 666;
        eval { 1; };
        $obj->_collect_system_data;
        $self->assert_equals(0, $obj->{errno});
    };
    die "$@" if $@;
}

sub test_throw {
    my $self = shift;

    # Secure with eval
    eval {
        # Simple throw
        eval {
            open FILE, "filenotfound.$$";
            Exception::System->throw;
        };
        my $obj1 = $@;
        $self->assert_not_null($obj1);
        $self->assert($obj1->isa("Exception::System"), '$obj1->isa("Exception::System")');
        $self->assert($obj1->isa("Exception::Base"), '$obj1->isa("Exception::Base")');
        $self->assert_equals("$ENOENT\n", $obj1->stringify(1));
        $self->assert($obj1->{errstr});
        $self->assert_equals('ENOENT', $obj1->{errname});
        $self->assert_equals(__PACKAGE__ . '::test_throw', $obj1->{caller_stack}->[3]->[3]);
        $self->assert(ref $self, ref $obj1->{caller_stack}->[3]->[8]);

        # Rethrow
        eval {
            chdir $0;
            $obj1->throw;
        };
        my $obj2 = $@;
        $self->assert_not_null($obj2);
        $self->assert($obj2->isa("Exception::System"), '$obj2->isa("Exception::System")');
        $self->assert($obj2->isa("Exception::Base"), '$obj2->isa("Exception::Base")');
        $self->assert_null($obj2->{message});
        $self->assert($obj2->{errstr});
        $self->assert_equals('ENOENT', $obj2->{errname});
        $self->assert_equals(__PACKAGE__ . '::test_throw', $obj2->{caller_stack}->[3]->[3]);
        $self->assert_equals(ref $self, ref $obj2->{caller_stack}->[3]->[8]);
    };
    die "$@" if $@;
}

sub test_with {
    my $self = shift;

    eval {
        my $obj1 = Exception::System->new(message=>'Message');
        $obj1->{errstr} = 'Errstr';
        $self->assert_equals(0, $obj1->with(undef));
        $self->assert_equals(0, $obj1->with(message=>undef));
        $self->assert_equals(1, $obj1->with('Message'));
        $self->assert_equals(1, $obj1->with(message=>'Message'));
        $self->assert_equals(0, $obj1->with(errstr=>undef));
        $self->assert_equals(1, $obj1->with(errstr=>'Errstr'));
        $self->assert_equals(1, $obj1->with(errstr=>sub {/Errstr/}));
        $self->assert_equals(0, $obj1->with(errstr=>sub {/false/}));
        $self->assert_equals(1, $obj1->with(errstr=>qr/Errstr/));
        $self->assert_equals(0, $obj1->with(errstr=>qr/false/));
    };
    die "$@" if $@;
}

sub test_stringify {
    my $self = shift;

    eval {
        my $obj = Exception::System->new(message=>'Stringify');

        $self->assert_not_null($obj);
        $self->assert($obj->isa("Exception::System"), '$obj->isa("Exception::System")');
        $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
        $self->assert_equals('', $obj->stringify(0));
        $self->assert_equals("Stringify\n", $obj->stringify(1));
        $self->assert_matches(qr/Stringify at .* line \d+.\n/s, $obj->stringify(2));
        $self->assert_matches(qr/Exception::System: Stringify at .* line \d+\n/s, $obj->stringify(3));
        $self->assert_equals("Message\n", $obj->stringify(1, "Message"));
        $self->assert_equals("Unknown system exception\n", $obj->stringify(1, ""));

        $obj->{errstr} = 'Error';
        $self->assert_equals('', $obj->stringify(0));
        $self->assert_equals("Stringify: Error\n", $obj->stringify(1));
        $self->assert_matches(qr/Stringify: Error at .* line \d+.\n/s, $obj->stringify(2));
        $self->assert_matches(qr/Exception::System: Stringify: Error at .* line \d+\n/s, $obj->stringify(3));
        $self->assert_equals("Message: Error\n", $obj->stringify(1, "Message"));
        $self->assert_equals("Error\n", $obj->stringify(1, ""));

        $self->assert_equals(1, $obj->{defaults}->{verbosity} = 1);
        $self->assert_equals(1, $obj->{defaults}->{verbosity});
        $self->assert_equals("Stringify: Error\n", $obj->stringify);
        $self->assert_not_null($obj->{defaults}->{verbosity});
        $obj->{defaults}->{verbosity} = Exception::System->ATTRS->{verbosity}->{default};
        $self->assert_equals(1, $obj->{verbosity} = 1);
        $self->assert_equals("Stringify: Error\n", $obj->stringify);

        $self->assert_equals("Stringify: Error\n", "$obj");
    };
    die "$@" if $@;
}

sub test_try {
    my $self = shift;

    eval {
        eval { 1; };
        my $v1 = Exception::System->try(eval { 1; });
        $self->assert_equals(1, $v1);
        my $e1 = Exception::System->catch(my $obj1);
        $self->assert_equals(0, $e1);
        $self->assert_null($obj1);

        eval { 1; };
        my $v2 = Exception::System->try(eval { die "Die 2\n"; });
        $self->assert_null($v2);
        my $e2 = Exception::System->catch(my $obj2);
        $self->assert_equals(1, $e2);
        $self->assert_not_null($obj2);
        $self->assert($obj2->isa("Exception::System"), '$obj2->isa("Exception::System")');
        $self->assert($obj2->isa("Exception::Base"), '$obj2->isa("Exception::Base")');
        $self->assert_equals("Die 2\n", $obj2->{message});
    }
}

1;
