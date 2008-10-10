#!/usr/bin/env python

import xlrd
import sys
import csv
import yaml

# slurp entire input into string
input = sys.stdin.read()

# book = xlrd.open_workbook(filename = "/dev/stdin")
book = xlrd.open_workbook(file_contents = input)
sheet = book.sheet_by_index(0)

writer = csv.writer(sys.stdout, delimiter = "\t")

for rownum in range(sheet.nrows)[0:]:
  row = []

  for cell in sheet.row(rownum):
    row.append(cell.value)

  writer.writerow(row)

stats = { ':nrows': sheet.nrows }
sys.stderr.write(yaml.dump(stats, default_flow_style = False))
