#!/usr/bin/env perl

use strict;
use Getopt::Long; # for GetOptions()
use Data::UUID;
use File::Path; # for mkpath, rmtree
use File::Temp;   # for tempdir()
use File::Copy;
use YAML::Syck;

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

my $dir = File::Temp::tempdir("numbrary.XXXX", DIR => $ENV{TMPDIR});
# print STDERR "Output to $dir\n";
# chdir $dir;

# TODO: deal with redirects, needs to pass back the ultimate target URI
# TODO: consider doing automatic retries with curl --retry
# TODO: consider more info in write-out

my $output = "output";

my $cmd = "curl --fail --silent '$uri' --write-out '%{http_code} %{content_type}' --output '$dir/$output'";
my $results = `$cmd`;
my $curl_error = $? >> 8;

my ($http_status, $content_type) = $results =~ /^(\d+) (.*)/;

my $stats = {};

if ($curl_error == 0) {
  $stats->{':http_status'} = $http_status,
  $stats->{':content_type'} = $content_type,

  my $uuid = lc(Data::UUID->new->create_str);
  my ($one, $two) = $uuid =~ /^(..)(..)/;
  my $fullpath = "$root/$one/$two/$uuid";

  mkpath("$root/$one/$two"); # no error checking, OK if path exists already
  move("$dir/$output", $fullpath);

  $stats->{':storage_id'} = $uuid;
} else {
  $stats->{':curl_error'} = $curl_error;
}

# my $cmd = "curl --silent '$uri' > $fullpath";
# print STDERR "$cmd\n";
# (system($cmd) == 0) or die $!;

print Dump($stats);
# print $uuid;

rmtree($dir);

exit;
