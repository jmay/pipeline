#!/usr/bin/perl

use strict;
use Text::CSV_XS;
use Getopt::Long;
use YAML::Syck;

=head1 NAME

stats.pl - produce YAML statistics on the input

=head1 DESCRIPTION

Input passed unchanged to output

Records are inspected on the way through and statistics are written in YAML to stderr.

=head1 CONTRACT

NSF for input (and output)

YAML output for stats

=head1 OPTIONS

None

=head1 TODO

Assemble column metrics:

* number of distinct values for strings
* min/max values for numerics

=cut

my $USAGE = "usage: stats.pl";

my $stats = {
  nrows => 0,
  ncols => 0,
  colcounts => {}, # map from column count to number of rows with that count; *should* have exactly one member
  columns => [], # array of column stats
};

######################################################################

my $csv_options = {
  binary => 1,
  sep_char => "\t",
};
my $csv = Text::CSV_XS->new($csv_options);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

# my @columns;

while (<>) {
  if (my $status = $csv->parse($_)) {
    my @fields = $csv->fields;
    print;

    $stats->{nrows}++; # count the rows
    $stats->{colcounts}->{scalar(@fields)}++; # count the number of columns in each row

    for my $colnum (0..$#fields) {
      my $thiscol = $stats->{columns}->[$colnum];
      my $thisval = $fields[$colnum];

      if ($thisval =~ /\d+/) {
        # numeric

        if (!defined $stats->{columns}->[$colnum]->{min}) {
          $thiscol->{min} = $thisval;
          $thiscol->{max} = $thisval;
        } else {
          $thiscol->{min} = $thisval if $thisval < $thiscol->{min};
          $thiscol->{max} = $thisval if $thisval > $thiscol->{max};
        }
      }

      if ($thisval =~ /[A-Za-z]+/) {
        # text

        $thiscol->{unique_values}->{$thisval}++;
      }
    }
  }
}

if (scalar(keys %{$stats->{colcounts}}) == 1) {
  $stats->{ncols} = (keys %{$stats->{colcounts}})[0];
}
# my @colcounts = keys %{$stats->{ncols}};
# if (scalar(@colcounts) == 1) {
#   my $ncolumns = @colcounts[0];
#   for my $i (0..$ncolumns-1) {
#     
#   }
# }

print STDERR Dump($stats);
