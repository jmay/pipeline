#!/usr/bin/perl

use strict;
use encoding 'utf8';

use Getopt::Long;
use IO::Handle;
use IO::Wrap;
use Text::CSV_XS;
use YAML::Syck;

=head1 NAME

tsv.pl - clean input tab-separate data

=head1 DESCRIPTION

Reads TSV from stdin, writes TSV to stdout, but applies cleaning process:

* Removes leading and trailing whitespace and quotes from all fields

* Skips blank lines

=head1 OPTIONS

  --delim delim [OPTIONAL] expect delim in the source instead of comma
  --eol eol [OPTIONAL] specifies end-of-line string (options are 'cr', 'lf' ,'crlf')

=cut

my $USAGE = "usage: tsv.pl\n";
my ($delimiter, $headers, $footers, $eol);
GetOptions(
  'eol=s' => \$eol,
  );

# source can have a variety of line terminators
# this is the best way I've found to catch the possibilities I've encountered so far
if ($eol) {
  $eol = "\015" if $eol eq 'cr';
  $eol = "\012" if $eol eq 'lf';
  $eol = "\015\012" if $eol eq 'crlf';
  $/ = $eol;
}

my $csv_in_options = {
  binary => 1,
  sep_char => "\t",
  eol => $/,
};
my $csv_out_options = {
  binary => 1,
  sep_char => "\t",
  eol => "\n",
  quote_char => '', # no quoting in the TSV output; all whitespace is crushed so no embedded delims
};

my $csv_in = Text::CSV_XS->new($csv_in_options);
my $csv_out = Text::CSV_XS->new($csv_out_options);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $nrows = 0;
my %ncolumns;

my $io = wraphandle(\*STDIN);
# while (my $row = $csv_in->getline($io)) {
while (<STDIN>) {
  chomp;

  if (my $status = $csv_in->parse($_)) {
    my @row = $csv_in->fields;
  
    # strip leading and trailing whitespace, compress internal whitespace to single space (on all fields)
    my @fields = map { s/\s+/ /g; $_ } map { s/^\s*|\s*$//g; $_ } @row;

    # assumes that Text::CSV_XS will make any quote wrappers go away

    my @nonblank_fields = grep { ! /^$/ } @fields;
    if ($#nonblank_fields > 0) {
      # write output only if there is at least one field with data

      if ($csv_out->combine(@fields)) {
        print $csv_out->string;
      } else {
        print "OUCH!\n";
      }

      $ncolumns{scalar(@fields)}++;
      $nrows++;
    }
  }
}

# write the execution statistics to stderr
my $results = {
  ':nrows' => $nrows,
  # ':rejected_rows' => scalar(@errors),
  ':ncolumns' => \%ncolumns,
};
print STDERR Dump($results);

# # write the data records to stdout
# for my $row (@rows) {
#   if ($csv_out->combine(@$row)) {
#     print $csv_out->string;
#   }
# }
