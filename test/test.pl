#!/usr/bin/env perl

use strict;
use File::Basename;
use Getopt::Std;
use POSIX qw(mkfifo);
use File::Temp; # for tempdir
use YAML::Syck qw(Load Dump LoadFile DumpFile);
use Storable; $Storable::canonical = 1; # for runlog hash comparison
use Cwd;


my %opts;
getopts("fv", \%opts) or die "usage: test.pl [-f] [tests]";

my $dirname = dirname(__FILE__);
chdir $dirname or die $!;

if (scalar(@ARGV) > 0) {
  for my $testcase (@ARGV) {
    runtest($testcase)
  }
  exit;
}

my $testdir = File::Temp::tempdir("pipeline_test.XXXX", DIR => $ENV{TMPDIR});

opendir DIR, "." or die $!;
for my $testcase (readdir DIR) {
  next unless -d $testcase && $testcase !~ /^\./;
#   print $testcase, "\n";
  runtest($testcase);
}
closedir DIR;


sub runtest {
  my ($testcase) = @_;

  my $casedir = getcwd() . "/" . $testcase;

  my @extra_inputs = glob("$casedir/input[0-9]*");
  my $extra_args = join(' ', map { "--input $_" } @extra_inputs);

  if ($opts{f}) {
    # -f provided; this updates the test case, so overwrite the output
    print "$testcase OVERWRITE\n";
    my $cmd = "../bin/pipeline.pl --input $casedir/input $extra_args --recipe $casedir/recipe --output $casedir/output --runlog $casedir/runlog";
    print STDERR $cmd, "\n";
    system($cmd);
  } else {
    # runs the test case and compares output to expectation

    my $cmd = "../bin/pipeline.pl --input $casedir/input $extra_args --recipe $casedir/recipe --output $testdir/output --runlog $testdir/runlog";

    print STDERR "RUNNING: $testcase\n";
    print STDERR $cmd, "\n" if $opts{v};
    system($cmd);

    my $expected_runlog = LoadFile("$casedir/runlog");
    my $actual_runlog = LoadFile("$testdir/runlog");
    if (Storable::freeze( $actual_runlog->{stagelogs} ) ne Storable::freeze( $expected_runlog->{stagelogs} )) {
      print STDERR "RUNLOG MISMATCH\n";
      system "diff $casedir/runlog $testdir/runlog;"
    }

    if (`cmp $casedir/output $testdir/output`) {
      print STDERR "OUTPUT MISMATCH\n";
      system "diff $casedir/output $testdir/output";
    }

    # if (`cmp $testcase/runlog $testdir/runlog`) {
    #   print STDERR "RUNLOG MISMATCH\n";
    #   system "diff $testcase/runlog $testdir/runlog;"
    # }
  }
}
