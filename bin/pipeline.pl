#!/usr/bin/env perl

use strict;
use Getopt::Long; # for GetOptions()
use File::Temp;   # for tempdir()
use File::Slurp;  # for read_file()
use YAML::Syck qw(Load Dump LoadFile DumpFile);
$YAML::Syck::ImplicitTyping = 1;  # for compatibility with ruby & others
use Cwd qw(getcwd abs_path);
use File::Basename;
use LWP::UserAgent; # for postback
use Proc::Daemon;

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
  --output file [optional, defaults to stdout]
  --runlog file [optional, defaults to stderr]
  --postback url [optional, no POST attempt if missing]

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

my $USAGE = "usage: pipeline.pl --input source --recipe recipe --output destination --runlog metadata [--postback url] [--background]";

my (@inputs, $recipe_file, $output, $runlog, $postback_url);
my $background = 0;
GetOptions(
  'input=s' => \@inputs,
  'recipe=s' => \$recipe_file,
  'output=s' => \$output,
  'runlog=s' => \$runlog,
  'postback=s' => \$postback_url,
  'background' => \$background
  );
die $USAGE unless @inputs && defined($recipe_file); # && defined($output) && defined($runlog);
# $output ||= "&1";
# $runlog ||= \*STDERR;

for my $file (@inputs) {
  if (!-r $file) {
    die "Can't read input $file";
  }
}
die "Can't read recipe $recipe_file" if !-r $recipe_file;

my $TOOLPATH = dirname(abs_path($0)) . "/../mod";
#$ENV{PATH} = "$TOOLPATH:$ENV{PATH}"; # so that pipeline execution will find the command modules

##################################################

my $dir = File::Temp::tempdir("numbrary.XXXX", DIR => $ENV{TMPDIR});

Proc::Daemon::Init if $background;

##################################################
# ASSEMBLE THE PIPELINE

my $recipe_stages = LoadFile($recipe_file);
my @chain;
my $i = 0;
my $secondary_input_num = 1;
for my $stage (@$recipe_stages) {
  my $args = $stage->{args} || $stage->{':args'}; # either string or ruby-symbol are valid
  my @arglist;
  if ($args) {
    while (my ($param, $value) = each(%{$args})) {
      $param =~ s/^://; # delete any leading colon
      if ($param =~ /input/) {
        push @arglist, "--input input$secondary_input_num";
        $secondary_input_num++;
      } elsif (UNIVERSAL::isa($value, "ARRAY")) {
        for (@$value) {
          push @arglist, "--$param '$_'";
        }
      } else {
        push @arglist, "--$param '$value'";
      }
    }
  }
  my $argstring = join(' ', @arglist);

  my $command = $stage->{command} || $stage->{':command'}; # either string or ruby-symbol are valid
  if (!$command) {
    push @chain, "(error.rb $argstring 2>log$i)";
  } elsif ($command eq 'extract') {
    my ($fh, $codefile) = File::Temp::tempfile("extract.XXXX", DIR => $dir, UNLINK => 0);
    print $fh $stage->{code};
    close $fh;
    # push @chain, "($TOOLPATH/extract.rb $args $codefile 2>log$i)";
    push @chain, "($TOOLPATH/extract.rb $argstring $codefile 2>log$i)";
  } else {
    # push @chain, "($TOOLPATH/$stage->{command} $args 2>log$i)";
    push @chain, "($TOOLPATH/$command $argstring 2>log$i)";
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

for my $i (0..$#inputs) {
  runbg "cat $inputs[$i] >$dir/input$i";
}

if ($output) {
  # output filename was provided
  run "mkfifo $dir/output";
  runbg "cat $dir/output >$output";
} elsif ($background) {
  # no output filename, but run in background so leave in 'output' file
} else {
  # no output filename, run in foreground, output to stdout
  run "mkfifo $dir/output";
  runbg "cat $dir/output";
}

##################################################
# RUN THE PIPELINE

my $cwd = getcwd;
print LOG "chdir $dir\n";
chdir $dir;

my $codes = run "cat input0 | $recipe_pipeline >output; echo \${PIPESTATUS[*]}";
my @status_codes = split(/\s+/, $codes);
shift(@status_codes);

print LOG scalar(localtime), ": done\n";

print LOG "chdir $cwd\n";
chdir $cwd;

close LOG;

##################################################
# ASSEMBLE RUNLOG

my @masterlog = read_file("$dir/masterlog");
chomp @masterlog;

my @stagelogs;
my @stage_errors;
# for my $i (0..$#recipe_stages) {
for my $i (0..$#chain) {
  if ($status_codes[$i] != 0) {
    my @errors = read_file("$dir/log$i");
    push @stage_errors, \@errors;
    push @stagelogs, { ':errors' => \@errors, ':error_code' => $status_codes[$i] };
  } else {
    my $stats = eval { LoadFile("$dir/log$i") };
    if ($@) {
      push @stagelogs, { 'error' => $@ }; # TODO: need test case for this
    } else {
      push @stagelogs, $stats;
    }
  }
}

my $runlog_data = {
  stagelogs => \@stagelogs,
  actions => \@masterlog,
};

# activity log is written out as YAML
if ($runlog) {
  # runlog filename provided, write to there
  DumpFile($runlog, $runlog_data);
} elsif ($background) {
  # no filename, but in background, so leave in 'runlog' file
  DumpFile("$dir/runlog", $runlog_data);
} else {
  # no filename, running in foreground, output to stderr
  print STDERR Dump($runlog_data);
}
# open(RUNLOG, ">$runlog") or die $!;
# print RUNLOG Dump($runlog_data);
# close RUNLOG;


##################################################
# POSTBACK - transmit acknowledgement of completion
# No checking of the response to the postback, this is fire-and-forget
# On postback, don't clean up the working directory, leave it for the recipient to take care of

if ($postback_url) {
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);

  my $response = $ua->post($postback_url, [ 'response' => Dump({':dir' => $dir, ':errors' => \@stage_errors}) ]);

  # ignore the response
  # if ($response->is_success) {
  #   print $response->decoded_content;  # or whatever
  # }
  # else {
  #   print $response->status_line;
  # }
} else {
  # delete the working directory and all its contents
  run "/bin/rm -rf $dir";
}

exit;

##################################################

sub run {
  my ($cmd) = @_;

  print LOG scalar(localtime), ": $cmd\n";

  open(RUNME, ">$dir/runme.bash") or die $!;
  print RUNME $cmd;
  close RUNME;
  $_ = `bash $dir/runme.bash`;
  unlink "$dir/runme.bash";

  # $_ = `$cmd`;

  $? and return; #die "command failed: $!";
  chomp;
  return $_;
}

sub runbg {
  my ($cmd) = @_;

  print LOG scalar(localtime), ": $cmd &\n";
  system("$cmd &");
}
