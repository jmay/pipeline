#!/usr/bin/env perl

use strict;
use File::Basename;
use Getopt::Std;
use POSIX qw(mkfifo);

my %opts;
getopts("f", \%opts) or die "usage: test.pl [-f] [tests]";

my $dirname = dirname(__FILE__);
chdir $dirname or die $!;

if (scalar(@ARGV) > 0) {
  for my $testcase (@ARGV) {
    runtest($testcase)
  }
  exit;
}

opendir DIR, "." or die $!;
for my $testcase (readdir DIR) {
  next unless -d $testcase && $testcase !~ /^\./;
#   print $testcase, "\n";
  runtest($testcase);
}
closedir DIR;


sub runtest {
  my ($testcase) = @_;

  my @extra_inputs = glob("$testcase/input[0-9]*");
  my $extra_args = join(' ', map { "--input $_" } @extra_inputs);

  if ($opts{f}) {
    # -f provided; this updates the test case, so overwrite the output
    print "$testcase OVERWRITE\n";
    my $cmd = "../bin/pipeline.pl --input $testcase/input $extra_args --recipe $testcase/recipe --output $testcase/output --runlog $testcase/runlog";
    print STDERR $cmd, "\n";
    system($cmd);
  } else {

    my $cmd = "../bin/pipeline.pl --input $testcase/input $extra_args --recipe $testcase/recipe --output test-output --runlog test-runlog";

    print STDERR $cmd, "\n";
    system($cmd);

    system "diff $testcase/output test-output";
    system "diff $testcase/runlog test-runlog";
  }
}
