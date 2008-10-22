#!/usr/bin/env python

import xlrd
import sys
import csv
import yaml
import datetime

# slurp entire input into string
input = sys.stdin.read()

# with default formatting_info=False it doesn't pull the merged_cells info
book = xlrd.open_workbook(file_contents = input, formatting_info = True)
sheet = book.sheet_by_index(0)

# gather all the merge-cell info
merges = {}
for crange in sheet.merged_cells:
  rlo, rhi, clo, chi = crange
  for rowx in xrange(rlo, rhi):
    for colx in xrange(clo, chi):
      key = "%(rowx)d,%(colx)d" % vars()
      merges[key] = "%(rlo)d,%(clo)d" % vars()

writer = csv.writer(sys.stdout, delimiter = "\t")

for rownum in range(sheet.nrows)[0:]:
  row = []

  for colnum, cell in enumerate(sheet.row(rownum)):

    if cell.ctype == 3:
      # date
      dtuple = xlrd.xldate_as_tuple(cell.value, book.datemode)
      row.append(datetime.date(dtuple[0], dtuple[1], dtuple[2]).strftime("%Y-%m-%d"))
    else:
      # numbers and strings
      mergekey = "%(rownum)d,%(colnum)d" % vars()

      if cell.value == "":
        # cell is empty, look in the merge store to see if we need to replicate a value
        if mergekey in merges:
          row.append(merges[merges[mergekey]])
        else:
          row.append("")
      else:
        row.append(cell.value)

        # if this is the top-left cell in a merge area, then stash the value for replication later
        if mergekey in merges:
          if merges[mergekey] == mergekey:
            merges[mergekey] = cell.value

  # Truncate blank cells from the end of each row.
  # This will make it easier to guess the number of columns in the source.
  while len(row) > 0 and row[-1] == '':
    row.pop()

  # TODO: A blank line will be emitted for empty source rows; is this what we want?
  writer.writerow(row)

stats = { ':nrows': sheet.nrows }
sys.stderr.write(yaml.dump(stats, default_flow_style = False))
