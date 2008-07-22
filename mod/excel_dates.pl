#!/usr/bin/env perl

use strict;
use warnings;
use encoding 'utf8';
use Getopt::Long; # for GetOptions()
use DateTime::Format::Excel;
use Text::CSV_XS;
use YAML::Syck;

my $USAGE = "usage: excel_dates.pl [--column colnum]\n";

my ($colnum);
GetOptions(
  'column=i' => \$colnum,
);

my $csv_options = {
  binary => 1,
  sep_char => "\t",
  quote_char => ''
};
my $csv_out = Text::CSV_XS->new($csv_options);

my $nrows = 0;
while (<STDIN>) {
  chomp;
  my @fields = split(/\t/);

  my $val = $fields[$colnum];
  if ($val && $val =~ /^\d+/) {
    my $datetime = DateTime::Format::Excel->parse_datetime($val);
    $fields[$colnum] = $datetime->ymd;
  }

  my $status = $csv_out->combine(@fields);
  print $csv_out->string(), "\n";
  $nrows++;
}

my $stats = {
  ':nrows' => $nrows,
};
print STDERR Dump($stats);
