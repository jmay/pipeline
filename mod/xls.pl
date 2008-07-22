#!/usr/bin/env perl

use strict;
use warnings;
use encoding 'utf8';
use Getopt::Long; # for GetOptions()
use Spreadsheet::ParseExcel;
use DateTime::Format::Excel;
use Text::CSV_XS;
use YAML::Syck;

my $USAGE = "usage: xls.pl [--page N]\n";

my $pagenum = 0;
GetOptions(
  'pagenum=i' => \$pagenum,
);

my $excel = Spreadsheet::ParseExcel::Workbook->Parse(\*STDIN);
my $sheets = $excel->{Worksheet};

my $csv_options = {
  binary => 1,
  sep_char => "\t",
  quote_char => ''
};
my $csv_out = Text::CSV_XS->new($csv_options);

my $nrows = 0;
process_sheet($sheets->[$pagenum]); # ignore all but one page

my $stats = {
  ':nrows' => $nrows,
  # no rejected-rows count here; we shouldn't be 'rejecting' anything, just converting as much as possible
};
print STDERR Dump($stats);


sub process_sheet {
  my ($sheet) = @_;

  $sheet->{MaxRow} ||= $sheet->{MinRow};
  my @rows = ($sheet->{MinRow} .. $sheet->{MaxRow});

  for my $row (@rows) {
    my @cells = process_row($sheet, $row);
    if (@cells) {
      my $status = $csv_out->combine(@cells);
      print $csv_out->string(), "\n";
      $nrows++;
    }
  }
}

sub process_row {
  my ($sheet, $row) = @_;

  my @cells;
  foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
    my $cell = $sheet->{Cells}[$row][$col];
    return if !$cell;
    my $val = $cell->{Val} || '';
    if ($cell && ($cell->{Type} eq 'Date')) {
      my $datetime = DateTime::Format::Excel->parse_datetime( $val );
      $val = $datetime->ymd;
    } else {
      # remove non-ascii junk from strings, e.g. em-dashes
      $val =~ s/[[:^print:]]//g if $val;
    }
    push @cells, $val;
  }
  return @cells;
}
