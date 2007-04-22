#!/usr/bin/perl
use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Exception::System',
    VERSION_FROM    => 'lib/Exception/System.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PMLIBDIRS       => [ 'lib' ],
    PREREQ_PM       => {
        'Exception::Base'       => 0.02,
        'Test::Unit'            => 0, 
    },
    AUTHOR          => 'Piotr Roszatycki <dexter@debian.org>',
    ABSTRACT        => 'Exception class for system or library calls'
);
