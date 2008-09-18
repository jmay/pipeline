#!/usr/bin/env perl

use strict;
use Text::CSV_XS;
use Getopt::Long;
use YAML::Syck;

=head1 NAME

replace_column.pl - substitute values in stdin using a mapping from a named file

=head1 DESCRIPTION

Read primary source from stdin, merge with secondary source, write replaced records to stdout

=head1 CONTRACT

Standard NSF expectations for both stdin and command-line source files

Expects that secondary source rows will be unique based on the key column;
this expectation does not apply to the primary source

Output will be NSF

=head1 OPTIONS

  --file filename [REQUIRED] file to read secondary source from
  --cola colnum [REQUIRED] column in stdin to match on (starting from zero)
  --colb colnum [REQUIRED] column in secondary source to match with (starting from zero)
  --colc colnum [REQUIRED] column in the secondary source to replace

=head1 TODO

What to do if you merge with a source that is missing some mappings?  Does this have an implicit filter?

=cut

my $USAGE = "usage: replace_column.pl --file filename --cola colnum --colb colnum\n";

my ($secondary, $cola, $colb, $colc);
GetOptions(
  'file=s' => \$secondary,
  'cola=i' => \$cola,
  'colb=i' => \$colb,
  'colc=i' => \$colc,
);
die $USAGE unless defined($secondary) && defined($cola) && defined($colb) && defined($colc);

my $stats = {
  filter_rows => 0,
  nrows => 0,
};

######################################################################
## PULL THE SECONDARY SOURCE ROWS INTO MEMORY
######################################################################

my %replace;

my $csv_options = {
  binary => 1,
  sep_char => "\t",
  quote_char => '',
};
my $csv = Text::CSV_XS->new($csv_options);

open(SECONDARY, "<$secondary") or die $!;
binmode SECONDARY, ":utf8";
while (<SECONDARY>) {
  if (my $status = $csv->parse($_)) {
    my @fields = $csv->fields;

    $replace{$fields[$colb]} = $fields[$colc];
  }
}
close SECONDARY;

$stats->{filter_rows} = scalar(keys %replace);

######################################################################
## MERGE
######################################################################

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

while (<>) {
  if (my $status = $csv->parse($_)) {
    my @fields = $csv->fields;

    if ($replace{$fields[$cola]}) {
      splice(@fields, $cola, 1, $replace{$fields[$cola]});

      if ($csv->combine(@fields)) {
        $stats->{nrows}++;
        print $csv->string, "\n";
      }
    } else {
      $stats->{excluded_rows}++;
    }
  }
}

print STDERR Dump($stats);
