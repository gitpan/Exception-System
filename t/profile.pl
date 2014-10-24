#!/usr/bin/perl -d:DProf

use lib 'lib', '../lib';
use Exception::System;


my $n = 0;

foreach (1..10000) {
    try Exception eval { throw Exception::System message=>'Message'; };
    if (catch Exception my $e) {
        if ($e->isa('Exception') and $e->with('Message')) { $n++; }
    }
}

print "tmon.out data collected. Call dprofpp\n";
