#!/usr/bin/env perl

use strict;
use Getopt::Long; # for GetOptions()
use Data::UUID;

=head1 NAME

move_into_filetree.pl - copy file into the filetree

=head1 DESCRIPTION

Move a file so that it can be inject into the Numbrary components system.

=head1 OPTIONS

  --root directory [REQUIRED]
  --filename filename [REQUIRED]

=head1 REQUIRED MODULES

This script requires the following modules:

  Getopt::Long
  Data::UUID

=cut

##################################################
# PROCESS COMMAND-LINE OPTIONS

my $USAGE = "usage: move_into_filetree.pl --root directory --filename filename";

my ($root, $filename);
GetOptions(
  'root=s' => \$root,
  'filename=s' => \$filename,
  );
die $USAGE, "\n" unless defined($root) && defined($filename);

##################################################

my $uuid = lc(Data::UUID->new->create_str);
my ($one, $two) = $uuid =~ /^(..)(..)/;
my $fullpath = "$root/$one/$two/$uuid";

mkdir "$root/$one" or die "mkdir $root/$one failed: $!";
mkdir "$root/$one/$two" or die "mkdir $root/$one/$two failed: $!";
system("/bin/cp $filename $fullpath") == 0 or die "copy failed with error code $?";

print $uuid, "\n";
