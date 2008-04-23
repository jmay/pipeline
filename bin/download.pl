#!/usr/bin/env perl

use strict;
use Getopt::Long; # for GetOptions()
use Data::UUID;
use File::Path 'mkpath';

=head1 NAME

download.pl - download URI into the filetree

=head1 DESCRIPTION

Download a document in preparation for injection into the Numbrary components system.

=head1 OPTIONS

  --root directory [REQUIRED]
  --uri uri [REQUIRED]

=head1 REQUIRED MODULES

This script requires the following modules:

  Getopt::Long
  Data::UUID

=head1 TODO

More error checking: mkpath

Error messages to STDERR

Catching errors from curl

=cut

##################################################
# PROCESS COMMAND-LINE OPTIONS

my $USAGE = "usage: download.pl --uri uri --root root";

my ($root, $uri);
GetOptions(
  'root=s' => \$root,
  'uri=s' => \$uri,
  );
die $USAGE, "\n" unless defined($root) && defined($uri);

##################################################

my $uuid = lc(Data::UUID->new->create_str);
my ($one, $two) = $uuid =~ /^(..)(..)/;
my $fullpath = "$root/$one/$two/$uuid";

mkpath("$root/$one/$two"); # no error checking, OK if path exists already

my $cmd = "curl --silent '$uri' > $fullpath";
print STDERR "$cmd\n";
(system($cmd) == 0) or die $!;

print $uuid;

exit;
