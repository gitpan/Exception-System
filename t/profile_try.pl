#!/usr/bin/perl -d:DProf

use lib 'lib', '../lib';	
use Exception::Base 'Exception::System';

foreach (1..10000) {
    try eval { Exception::System->throw(message=>'Message') };
    if (catch my $e) {
        if ($e->isa('Exception::Base') and $e->with('Message')) { 1; }
    }
}

print "tmon.out data collected. Call dprofpp\n";
