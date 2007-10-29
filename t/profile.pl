#!/usr/bin/perl -d:DProf

use lib 'lib', '../lib';	
use Exception::Base ':all',
    'Exception::System';

my $n = 0;

foreach (1..10000) {
    try eval { Exception::System->throw(message=>'Message') };
    if (catch my $e) {
        if ($e->isa('Exception::System') and $e->with('Message')) { $n++; }
    }
}

print "tmon.out data collected. Call dprofpp\n";
