#!/usr/bin/env perl

=begin USAGE

    analyze.pl [--content-type "html"] < file

    input: file on STDIN
    output: recipe in YAML

=begin OPTIONS

    --input (optional, default is STDIN) file to read
    --content-type (optional, default is text/plain) hint to analyzer to look for html content
    --postback (optional) if provided, POSTs results back to this page instead of printing to STDOUT
    --background (optional) if == 1, runs as a daemon

=begin DESCRIPTION

Inspect the input file and attempt to produce a recipe that will convert the input to
a tab-separated data file that can be ingested by the structure-analysis stage.

Possible output recipes include:

* extract a <pre> section from HTML
* extract table from HTML
* tab-separated text
* comma-separated text
* whitespace-separated text

=cut

use strict;
use Getopt::Long; # for GetOptions()
use YAML::Syck qw(Load Dump LoadFile DumpFile);
use LWP::UserAgent; # for postback
use Proc::Daemon; # for background

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

##################################################

Proc::Daemon::Init if $background;

##################################################

my @recipe;

if ($mimetype =~ /html/i) {
  # parse HTML
} else {
  # plaintext - CSV, TSV, whitespace?
  $/ = undef;
  my $input;
  if ($file) {
    open(FD, $file) or die $!;
    my $bytes = sysread(FD, $input, 2000);
    close FD;
  } else {
    $input = <STDIN>;
  }

  # identify line delimiters
  # my @eols = $input =~ /(\n+|\r+)[\n\r]*/msg;
  # print STDERR "LINES: ", $#eols, "\n";
  # print STDERR int($eols[1]), "\n";

  my @tabs = $input =~ /\t/msg;
  if (scalar(@tabs) > 3) {
    # looks like TSV
    push @recipe, { ':command' => 'tsv.pl' };
  } else {
    my @commas = $input =~ /,/msg;
    if (scalar(@commas) > 3) {
      # looks like CSV
      push @recipe, { ':command' => "csv2tsv" };
    } else {
      push @recipe, { ':command' => "whitespace_separated.rb" };
    }
  }
}

##################################################

if ($postback_url) {
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);

  my $response = $ua->post($postback_url, [ 'response' => Dump(\@recipe) ]);
  # ignore the response
} else {
  # delete the working directory and all its contents
  print Dump(\@recipe);
}
