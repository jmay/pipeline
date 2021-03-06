#!/usr/bin/env perl

use strict;
use Getopt::Long; # for GetOptions()
use YAML::Syck; # for Dump()
use LWP::UserAgent; # for postback
use Proc::Daemon; # for background
use File::Temp;

=head1 NAME

coalesce - merge sources

=head1 DESCRIPTION

Same as `cat`ting together a list of files, plus YAML stats at the end.

The input files *ought* to be of the same structure, but this is not verified here.

=head1 OPTIONS

  --background
  --postback

  input filenames are obtained from ARGV

=cut

my $USAGE = "usage: coalesce.pl [--background] [--postback URL] [--sortcol sortcol] files...";

my $postback_url;
my $background = 0;
my $sortcol;
GetOptions(
  'postback=s' => \$postback_url,
  'background' => \$background,
  'sortcol=i' => \$sortcol
  );

my @inputs = @ARGV;
for my $input (@inputs) {
  die "Input file $input not found" unless -r $input;
}

my $dir = File::Temp::tempdir("numbrary.XXXX", DIR => $ENV{TMPDIR});

# do it with UNIX built-in cat and sort
my $sort = '';
if ($sortcol) {
  # sort -k counts columns starting from 1, Numbrary counts from zero
  my $sortkcol = $sortcol+1;
  # this crazy \$'\\t' business is to pass a tab to sort -t
  $sort = " | sort -t \$'\\t' -k$sortkcol -n";
}
my $cmd = "cat " . join(' ', @inputs) . " $sort > $dir/output";
print STDERR $cmd;
# open(OUTPUT, ">$dir/output") or die $!;

Proc::Daemon::Init if $background;

# my $nrows = 0;
# for my $input (@inputs) {
#   open(INPUT, "<$input") or die $!;
#   while(<INPUT>) {
#     print OUTPUT;
#     $nrows++;
#   }
#   close INPUT;
# }
# close OUTPUT;

system($cmd) == 0 or die $!;

my $response = {
  ':dir' => $dir
};

if ($postback_url) {
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);

  my $response = $ua->post($postback_url, [ 'response' => Dump($response) ]);
} else {
  print STDERR Dump($response);
}
