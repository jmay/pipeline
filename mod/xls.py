#!/usr/bin/env python

import xlrd
import sys
import csv

book = xlrd.open_workbook("/Users/jmay/Downloads/phosphate.xls")
sheet = book.sheet_by_index(0)

writer = csv.writer(sys.stdout, delimiter = "\t")

for rownum in range(sheet.nrows)[0:]:
  row = []

  for cell in sheet.row(rownum):
    row.append(cell.value)

  writer.writerow(row)

# stats
# stats = { ':nrows': sheet.nrows }
# print stats
