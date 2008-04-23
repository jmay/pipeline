#!/usr/bin/env python

import sys
import csv

# def unicode_csv_reader(unicode_csv_data, dialect=csv.excel, **kwargs):
#     # csv.py doesn't do Unicode; encode temporarily as UTF-8:
#     csv_reader = csv.reader(utf_8_encoder(unicode_csv_data),
#                             dialect=dialect, **kwargs)
#     for row in csv_reader:
#         # decode UTF-8 back to Unicode, cell by cell:
#         yield [unicode(cell, 'utf-8') for cell in row]
# 
# def utf_8_encoder(unicode_csv_data):
#     for line in unicode_csv_data:
#         yield line.encode('utf-8')
# 
reader = csv.reader(sys.stdin, delimiter="\t", quoting=csv.QUOTE_NONE)
writer = csv.writer(sys.stdout)

for row in reader:
  writer.writerow(row)
