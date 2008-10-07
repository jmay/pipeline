#!/usr/bin/env perl

=begin USAGE

    dissect.pl [--input file] [--postback URL] [--background]

=begin OPTIONS

    --input (optional, default is STDIN) file to read
    --postback (optional) if provided, POSTs results back to this page instead of printing to STDOUT
    --background (optional) if set, runs as a daemon

=begin DESCRIPTION

Inspect the input file, which is assumed to be TSV, and attempt to produce a recipe that will transform
from TSV to NSF and extract column metadata needed to representing the data fully within Numbrary.

=cut

use strict;
use Getopt::Long; # for GetOptions()
use YAML::Syck qw(Load Dump LoadFile DumpFile);
use LWP::UserAgent; # for postback
use Proc::Daemon; # for background
use File::Basename; # for dirname()
use IPC::Open3;

##################################################

my ($postback_url, $file);
my $mimetype = 'text/plain';
my $background = 0;
GetOptions(
  'input=s' => \$file,
  'content-type=s' => \$mimetype,
  'postback=s' => \$postback_url,
  'background' => \$background
  );

if ($file && !-r $file) {
  die "Can't read input file $file";
}

# my $dissector = `gem contents dataset | grep dissect`;
# chomp $dissector;
# die "Can't find dissector" if !$dissector;
# print "DISSECTOR IS [$dissector]\n";

my $dissector = dirname(__FILE__) . "/dissection.rb";
# print "DISSECTOR IS [$dissector]\n";

##################################################

Proc::Daemon::Init if $background;

##################################################

my @recipe;

my @rows;
open(INPUT, $file) or die $!;

# grab first 100 rows
my $i = 0;
push(@rows, <INPUT>) until $i >= 100 || eof(INPUT);

# sample from next 1000 or so rows
my $i = 0;
while ($i < 100 && !eof(INPUT)) {
  if (rand() < 0.1) {
    push(@rows, <INPUT>);
    $i++;
  }
}

close INPUT;

# now we should have <=200 rows to work with

my $pid = open3(\*CHLD_IN, \*CHLD_OUT, \*CHLD_ERR, "/usr/bin/env ruby $dissector");
print CHLD_IN @rows;
close CHLD_IN;
$/ = undef;
my $yaml = <CHLD_OUT>;

# open(DISSECT, "| /usr/bin/env ruby $dissector |") or die $!;
# print DISSECT @rows;
# close DISSECT;
# 
# $/ = undef;
# my $yaml = <DISSECT>;

##################################################

if ($postback_url) {
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);

  my $response = $ua->post($postback_url, [ 'response' => $yaml ]);
  # ignore the response
} else {
  # delete the working directory and all its contents
  print $yaml;
}
