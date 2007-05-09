package Exception::SystemTest;

use base 'Test::Unit::TestCase';

use Exception::System;

sub new {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

sub test_Exception_System_isa {
    my $self = shift;
    my $obj = Exception::System->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa('Exception::System'));
    $self->assert($obj->isa('Exception::Base'));
}

sub test_Exception_System_field_message {
    my $self = shift;
    my $obj = Exception::System->new(message=>'Message');
    $self->assert_equals('Message', $obj->{message});
    $self->assert_equals('New Message', $obj->{message} = 'New Message');
    $self->assert_equals('New Message', $obj->{message});
}

sub test_Exception_System_field_properties {
    my $self = shift;
    my $obj = Exception::System->new(message=>'Message', tag=>'Tag');
    $self->assert_equals('Tag', $obj->{properties}->{tag});
}

sub test_Exception_System_collect_system_data {
    my $self = shift;
    
    eval {
        my $obj = Exception::System->new(message=>'Collect');

        $self->assert_not_null($obj);
        $self->assert($obj->isa('Exception::Base'));
        $self->assert_equals('Collect', $obj->{message});
        $self->assert_null($obj->{errstr});
        $self->assert_null($obj->{errstros});
        $self->assert_null($obj->{errname});
        $self->assert_null($obj->{errno});
        
        eval { 1; };
        $obj->_collect_system_data;
        $self->assert_not_null($obj->{errstr});
        $self->assert_not_null($obj->{errstros});
        $self->assert_not_null($obj->{errname});
        $self->assert_not_null($obj->{errno});

        $obj->{errno} = 666;
        eval { 1; };
        $obj->_collect_system_data;
        $self->assert_equals(666, $obj->{errno});
        
        foreach my $errstr (undef, 'defined') {
            foreach my $errstros (undef, 'defined') {
                foreach my $errname (undef, 'defined') {
                    foreach my $errno (undef, 1) {
                        next if not defined $errstr and not defined $errstros
                            and not defined $errname and not defined $errno;
                        next if defined $errstr and defined $errstros
                            and defined $errname and defined $errno;
                        $obj->{errstr} = $errstr;
                        $obj->{errstros} = $errstros;
                        $obj->{errname} = $errname;
                        $obj->{errno} = $errno;
                        eval { 1; };
                        $obj->_collect_system_data;
                        $self->assert(not defined $obj->{errstr} or not defined $obj->{errstros}
                            or not defined $obj->{errname} or not defined $obj->{errno});
                    }
                }
            }
        }
        
    };
    die "$@" if $@;
}

sub test_Exception_System_throw {
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
        $self->assert($obj1->isa('Exception::System'));
        $self->assert($obj1->isa('Exception::Base'));
        $self->assert_equals("Unknown exception\n", $obj1->stringify(1));
        $self->assert($obj1->{errstr});
        $self->assert_equals('ENOENT', $obj1->{errname});
        $self->assert_equals(__PACKAGE__ . '::test_Exception_System_throw', $obj1->{caller_stack}->[3]->[3]);
        $self->assert(ref $self, ref $obj1->{caller_stack}->[3]->[8]);

        # Rethrow
        eval {
            chdir $0;
            $obj1->throw;
        };
        my $obj2 = $@;
        $self->assert_not_null($obj2);
        $self->assert($obj2->isa('Exception::System'));
        $self->assert($obj2->isa('Exception::Base'));
        $self->assert_null($obj2->{message});
        $self->assert($obj2->{errstr});
        $self->assert_equals('ENOENT', $obj2->{errname});
        $self->assert_equals(__PACKAGE__ . '::test_Exception_System_throw', $obj2->{caller_stack}->[3]->[3]);
        $self->assert_equals(ref $self, ref $obj2->{caller_stack}->[3]->[8]);
    };
    die "$@" if $@;
}

sub test_Exception_System_with {
    my $self = shift;

    eval {
        my $obj1 = Exception::System->new(message=>'Message');
        $obj1->{properties}->{message} = 'Tag';
	$obj1->{errstr} = 'Errstr';
        $self->assert_equals(0, $obj1->with(undef));
        $self->assert_equals(0, $obj1->with(message=>undef));
        $self->assert_equals(1, $obj1->with('Message'));
        $self->assert_equals(1, $obj1->with(message=>'Tag'));
        $self->assert_equals(1, $obj1->with(message=>sub {/Tag/}));
        $self->assert_equals(0, $obj1->with(message=>sub {/false/}));
        $self->assert_equals(1, $obj1->with(message=>qr/Tag/));
        $self->assert_equals(0, $obj1->with(message=>qr/false/));
	$self->assert_equals(1, $obj1->with(errstr=>'Errstr'));
    };
    die "$@" if $@;
}

sub test_Exception_System_stringify {
    my $self = shift;

    eval {
        my $obj = Exception::System->new(message=>'Stringify');

        $self->assert_not_null($obj);
        $self->assert($obj->isa('Exception::System'));
        $self->assert($obj->isa('Exception::Base'));
        $self->assert_equals('', $obj->stringify(0));
        $self->assert_equals("Stringify\n", $obj->stringify(1));
        $self->assert_equals("Stringify at unknown line 0.\n", $obj->stringify(2));
        $self->assert_equals("Exception::System: Stringify at unknown line 0\n", $obj->stringify(3));
        $self->assert_equals("Message\n", $obj->stringify(1, "Message"));

        $obj->{errstr} = 'Error';
        $self->assert_equals('', $obj->stringify(0));
        $self->assert_equals("Stringify: Error\n", $obj->stringify(1));
        $self->assert_equals("Stringify: Error at unknown line 0.\n", $obj->stringify(2));
        $self->assert_equals("Exception::System: Stringify: Error at unknown line 0\n", $obj->stringify(3));

        $self->assert_equals(3, $obj->{defaults}->{verbosity});
        $self->assert_equals(1, $obj->{defaults}->{verbosity} = 1);
        $self->assert_equals(1, $obj->{defaults}->{verbosity});
        $self->assert_equals("Stringify: Error\n", $obj->stringify);
        $self->assert_not_null($obj->{defaults}->{verbosity});
        $self->assert_equals(3, $obj->{defaults}->{verbosity} = Exception::System->FIELDS->{verbosity}->{default});
        $self->assert_equals(1, $obj->{verbosity} = 1);
        $self->assert_equals("Stringify: Error\n", $obj->stringify);
    };
    die "$@" if $@;
}

sub test_Exception_System_try {
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
        $self->assert($obj2->isa('Exception::System'));
        $self->assert_equals("Die 2\n", $obj2->{message});
    }
}

1;
