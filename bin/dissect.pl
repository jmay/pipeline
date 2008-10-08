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
# use IPC::Open3;
use IPC::Open2;
use File::Spec;

##################################################

my ($postback_url, $file);
my $background = 0;
GetOptions(
  'input=s' => \$file,
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

my $dissector = dirname(File::Spec->rel2abs(__FILE__)) . "/dissection.rb";
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

##################################################
# now we should have <=200 rows to work with

my $response;

my $pid = open2(*Reader, *Writer, $dissector);
print Writer @rows;
close Writer;
$/ = undef;
my $yaml = <Reader>;
$response = Load($yaml);

# my ($writer, $reader, $errfd);
# my $rc = system("echo | $dissector");
# my $pid = open3($writer, $reader, $errfd, $dissector);
# if ($!) {
#   $response->{':error'} = "TROUBLE on $dissector ($pid) ($rc): $! $@"
# } else {
#   print $writer @rows;
#   close $writer;
#   $/ = undef;
#   my $yaml = <$reader>;
#   $response = Load($yaml);
# 
#   my $errs = <$errfd>;
# 
#   $response->{':error'} = $errs if $errs;
#   # push @payload, {'response' => $yaml} if $yaml;
#   # push @payload, {'error' => $errs} if $errs;
# }

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

  my $response = $ua->post($postback_url, ['response' => Dump($response)]);
  # ignore the response
} else {
  # delete the working directory and all its contents
  print Dump($response);
}
