#!/usr/bin/env perl

use strict;
use Getopt::Long; # for GetOptions()
use YAML::Syck;

=head1 NAME

select_where.pl - restrict rows in TSV pipeline

=head1 DESCRIPTION

Read TSV from stdin, apply filter rules, write to stdout

Removes the select-by columns from the output, so the output has fewer columns than the input.

=head1 CONTRACT

Expects input in TSV

Expects input to have no empty lines

Expects input fields to have been stripped of leading & trailing whitespace

Expects input in UTF-8

Writes UTF-8 as output.

=head1 OPTIONS

  -f colnum [REQUIRED] column number to filter on
  -v value [REQUIRED] string value to match

=cut

my $USAGE = "usage: select_where.pl --column 'colnum' --value 'value' [--invert 1/0]\n";

my ($colnum, $value);
my $invert = 0;
GetOptions(
  'column=i' => \$colnum,
  'value=s' => \$value,
  'invert=i' => \$invert,
  );
die $USAGE unless defined($colnum) && defined($value);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

my $nrows = 0;
my $excluded_rows = 0;

while (<>) {
  my @fields = split(/\t/);
  my $match = ($fields[$colnum] eq $value);
  if ($match xor $invert) {
    # output is the input line with the match column removed
    splice @fields, $colnum, 1;
    print join("\t", @fields);
    $nrows++;
  } else {
    $excluded_rows++;
  }
}

my $stats = {
  ':nrows' => $nrows,
  ':excluded_rows' => $excluded_rows,
};
print STDERR Dump($stats);
