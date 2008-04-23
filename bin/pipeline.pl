#!/usr/bin/env perl

use strict;
use Getopt::Long; # for GetOptions()
use File::Temp;   # for tempdir()
use File::Slurp;  # for read_file()
use YAML::Syck qw(Load Dump LoadFile DumpFile);
use Cwd qw(getcwd abs_path);
use File::Basename;

=head1 NAME

pipeline.pl - use recipe to build an output file based on one or more inputs and compile an activity log

=head1 DESCRIPTION

Numbrary data processing pipeline control program.

Recipe is a multiline script; each line must define exactly one stage of the processing pipeline.

Recipe stages may optionally take additional input files, referred to in the recipe as
'input1', 'input2', etc.  Matching files must be declared in order as --input arguments
to pipeline.pl.

=head1 TOOLCHAIN COMPONENTS

  csv2tsv
  filter
  filter2
  merge
  sum

=head1 OPTIONS

  --input file [AT LEAST ONE REQUIRED]
  --recipe file [REQUIRED]
  --output file [REQUIRED]
  --runlog file [REQUIRED]

=head1 REQUIRED MODULES

This script requires the following modules:

  Getopt::Long
  File::Temp
  File::Slurp
  YAML::Syck
  Cwd

=head1 TODO

Recognize if recipe is not in expected format (YAML, array of pipeline stages with instructions)

Catch fatal errors, collect the messages into runlog, and clean up

Check for existence of input and recipe files

Pro-active way of reporting problems to support staff - does that belong here?

=cut

sub run;
sub runbg;

##################################################
# PROCESS COMMAND-LINE OPTIONS

my $USAGE = "usage: pipeline.pl --input source --recipe recipe --output destination --runlog metadata";

my (@inputs, $recipe_file, $output, $runlog);
GetOptions(
  'input=s' => \@inputs,
  'recipe=s' => \$recipe_file,
  'output=s' => \$output,
  'runlog=s' => \$runlog,
  );
die $USAGE, "\n" unless @inputs && defined($recipe_file); # && defined($output) && defined($runlog);
$output ||= "&1";
# $runlog ||= \*STDERR;

my $TOOLPATH = dirname(abs_path($0)) . "/../mod";
$ENV{PATH} = "$TOOLPATH:$ENV{PATH}"; # so that pipeline execution will find the command modules

##################################################

my $dir = File::Temp::tempdir("numbrary.XXXX", DIR => $ENV{TMPDIR});

##################################################
# ASSEMBLE THE PIPELINE

my $recipe_stages = LoadFile($recipe_file);
my @chain;
my $i = 0;
for my $stage (@$recipe_stages) {
  my @arglist;
  if ($stage->{args}) {
    while (my ($param, $value) = each(%{$stage->{args}})) {
      if (UNIVERSAL::isa($value, "ARRAY")) {
        for (@$value) {
          push @arglist, "--$param $_";
        }
      } else {
        push @arglist, "--$param $value";
      }
    }
  }
  my $args = join(' ', @arglist);

  if ($stage->{command} eq 'extract') {
    my ($fh, $codefile) = File::Temp::tempfile("extract.XXXX", DIR => $dir, UNLINK => 0);
    print $fh $stage->{code};
    close $fh;
    # push @chain, "($TOOLPATH/extract.rb $args $codefile 2>log$i)";
    push @chain, "(extract.rb $args $codefile 2>log$i)";
  } else {
    # push @chain, "($TOOLPATH/$stage->{command} $args 2>log$i)";
    push @chain, "($stage->{command} $args 2>log$i)";
  }
  $i++;
}
# my @recipe_stages = read_file($recipe);
# chomp @recipe_stages; # remove trailing newlines
# my @chain;
# my $i = 0;
# while ($_ = shift @recipe_stages) {
#   if (/^extract/) {
#     my @extract_code;
#     $_ = shift @recipe_stages;
#     while (/^\s+/) {
#       push @extract_code, $_;
#       $_ = shift @recipe_stages;
#     }
#     # print join("\n", @extract_code);
#     my ($fh, $codefile) = File::Temp::tempfile("extract.XXXX", DIR => $dir, UNLINK => 0);
#     print $fh join("\n", @extract_code), "\n";
#     close $fh;
#     push @chain, "($ENV{TOOLS}/extract.rb $codefile 2>log$i)";
#   }
#   push @chain, "($ENV{TOOLS}/$_ 2>log$i)" if $_;
# 
#   $i++;
# }
# # for my $i (0..$#recipe_stages) {
# #   push @chain, "($ENV{TOOLS}/$recipe_stages[$i] 2>log$i)";
# # }
my $recipe_pipeline = join(" | ", @chain);
# print STDERR $recipe_pipeline, "\n";
# exit;

##################################################
# CONNECT UP THE INPUTS AND OUTPUTS

open(LOG, ">$dir/masterlog") or die $!;

for my $i (0..$#inputs) {
  run "mkfifo $dir/input$i";
}

run "mkfifo $dir/output.nsf";

for my $i (0..$#inputs) {
  runbg "cat $inputs[$i] >$dir/input$i";
}

runbg "cat $dir/output.nsf >$output";

##################################################
# RUN THE PIPELINE

my $cwd = getcwd;
print LOG "chdir $dir\n";
chdir $dir;

run "cat input0 | $recipe_pipeline >output.nsf";

print LOG scalar(localtime), ": done\n";

print LOG "chdir $cwd\n";
chdir $cwd;

close LOG;

##################################################
# ASSEMBLE RUNLOG

my @masterlog = read_file("$dir/masterlog");
chomp @masterlog;

my @stagelogs;
# for my $i (0..$#recipe_stages) {
for my $i (0..$#chain) {
  my $stats = eval { LoadFile("$dir/log$i") };
  if ($@) {
    push @stagelogs, { 'error' => $@ };
  } else {
    push @stagelogs, $stats;
  }
}

my $runlog_data = {
  stagelogs => \@stagelogs,
  actions => \@masterlog,
};

# write the log of this script's activity to the runlog, as YAML
if ($runlog) {
  DumpFile($runlog, $runlog_data);
} else {
  print STDERR Dump($runlog_data);
}
# open(RUNLOG, ">$runlog") or die $!;
# print RUNLOG Dump($runlog_data);
# close RUNLOG;


# delete the working directory and all its contents
run "/bin/rm -rf $dir";

exit;

##################################################

sub run {
  my ($cmd) = @_;

  print LOG scalar(localtime), ": $cmd\n";
  $_ = `$cmd`;
  $? and return; #die "command failed: $!";
  chomp;
  return $_;
}

sub runbg {
  my ($cmd) = @_;

  print LOG scalar(localtime), ": $cmd &\n";
  system("$cmd &");
}
