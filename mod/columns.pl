#!/usr/bin/perl

use strict;
use Getopt::Long; # for GetOptions()
use Text::CSV_XS;
use YAML::Syck;

=head1 NAME

columns.pl - cut columns in TSV

=head1 DESCRIPTION

Read TSV from stdin, cut selected columns, write to stdout

Expects UTF-8 for input, writes UTF-8 as output.

=head1 OPTIONS

  --columns column-list [REQUIRED] list of columns to include in the output

=cut

my $USAGE = "usage: columns.pl --columns n,n-n,n";

my ($include);
GetOptions(
  'columns=s' => \$include,
  );
die $USAGE, "\n" unless defined($include);

my @cols = split(/\s*,\s*/, $include);
@cols = grep { /\d+/ } @cols;
die $USAGE, "\n" unless @cols && scalar(@cols);

my $csv_options = {
  binary => 1,
  sep_char => "\t",
  quote_char => ''
};

my $csv = Text::CSV_XS->new($csv_options);
my $csv_out = Text::CSV_XS->new($csv_options);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

my $nrows = 0;
while (<>) {
  if (my $status = $csv->parse($_)) {
    my @input_fields = $csv->fields;

    my @output_fields = @input_fields[@cols];

    if ($csv_out->combine(@output_fields)) {
      print $csv_out->string, "\n";
    }
    $nrows++;
  }
}

my $stats = {
  ':nrows' => $nrows,
  ':ncolumns' => scalar(@cols),
};
print STDERR Dump($stats);
