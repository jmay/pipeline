#!/usr/bin/perl

use strict;
use Getopt::Long; # for GetOptions()
use Text::CSV_XS;

=head1 NAME

cut - cut columns in TSV

=head1 DESCRIPTION

Read TSV from stdin, cut selected columns, write to stdout

Expects UTF-8 for input, writes UTF-8 as output.

=head1 OPTIONS

  --include column-list [REQUIRED] list of columns to include in the output

=cut

my $USAGE = "usage: cut --include n,n-n,n";

my ($include);
GetOptions(
  'include=s' => \$include,
  );
die $USAGE, "\n" unless defined($include);

my @cols = split(/\s*,\s*/, $include);
@cols = grep { /\d+/ } @cols;
die $USAGE, "\n" unless @cols && scalar(@cols);

my $csv_options = {
  binary => 1,
  sep_char => "\t",
};
my $csv = Text::CSV_XS->new($csv_options);
my $csv_out = Text::CSV_XS->new($csv_options);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

while (<>) {
  if (my $status = $csv->parse($_)) {
    my @input_fields = $csv->fields;

    my @output_fields = @input_fields[@cols];

    if ($csv_out->combine(@output_fields)) {
      print $csv_out->string, "\n";
    }
  }
}
