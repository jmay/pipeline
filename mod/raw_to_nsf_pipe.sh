#!/bin/bash

# Numbrary processing pipeline: convert raw data to the initial NSF file.

##################################################
# PROCESS COMMAND-LINE OPTIONS

RAW=SIFB0506.txt
OUTPUT=SIFB0506.nsf
OUTPUT_META=SIFB0506_meta.nsf
DELIM=";"
HEADERS=1
FOOTERS=0

##################################################

RM=/bin/rm

echo "SETTING UP" >&2

# create temporary working directory
DIR=`mktemp -d -t numbrary`

# set up named pipes for all the inputs
mkfifo $DIR/raw

# set up named pipes for the output
mkfifo $DIR/output.nsf
mkfifo $DIR/output_meta.nsf

echo "CONNECTING INPUTS & OUTPUTS" >&2

# connect up the inputs

cat $RAW > $DIR/raw &

# connect up the output

cat $DIR/output.nsf > $OUTPUT &
cat $DIR/output_meta.nsf > $OUTPUT_META &

echo "RUNNING THE PIPELINE" >&2

# run the pipeline from named pipes to named pipe

echo "cat $DIR/raw | $TOOLS/csv2tsv --delim $DELIM --headers $HEADERS --footers $FOOTERS > $DIR/output.nsf 2> $DIR/output_meta.nsf"
cat $DIR/raw | $TOOLS/csv2tsv --delim $DELIM --headers $HEADERS --footers $FOOTERS > $DIR/output.nsf 2> $DIR/output_meta.nsf

echo "CLEANING UP" >&2

# delete the working directory and all its contents
$RM -rf $DIR

echo "DONE" >&2
