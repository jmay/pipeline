#!/usr/bin/env perl

use strict;
use Text::CSV;
use Getopt::Long;

=head1 NAME

to_csv - read TSV, output CSV

=head1 DESCRIPTION

Input unchanged except for delimiter

=cut

my $csv_in_options = {
  binary => 1,
  sep_char => "\t",
};
my $csv_out_options = {
  binary => 1,
  sep_char => ",",
};

my $csv_in = Text::CSV->new($csv_in_options);
my $csv_out = Text::CSV->new($csv_out_options);

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

while (<>) {
  if (my $status = $csv_in->parse($_)) {
    my @fields = $csv_in->fields;

    if ($csv_out->combine(@fields)) {
      print $csv_out->string, "\n";
    }
  }
}

# while (<>) {
#   my @fields = split(/\t/);
#   print join(",", @fields);
# }
