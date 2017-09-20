#!/usr/bin/perl

use strict;
use warnings;
use Test2::V0;
use Test::Script;
use Test::More tests => 1;

script_compiles('asbru', 'Program compiles');

done_testing;
