#!/usr/bin/env perl

use strict;
use YAML;

my @columns;
while (<>) {
  chomp;
  push @columns, { ":label" => $_ };
}

print Dump(\@columns);
