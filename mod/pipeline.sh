#!/bin/bash

# Run a complete simulated Numbrary processing pipeline.

RM=/bin/rm

echo "SETTING UP"

# create temporary working directory
DIR=`mktemp -d -t numbrary`

# set up named pipes for all the inputs
mkfifo $DIR/source1
mkfifo $DIR/source2

# set up named pipe for the output
mkfifo $DIR/output

echo "CONNECTING INPUTS & OUTPUTS"

# connect up the inputs

cat /Users/jmay/Projects/Numbrary/DataSources/ca/schools/enrollment.tsv > $DIR/source1 &
cat /Users/jmay/Projects/Numbrary/DataSources/ca/schools/los_altos_schools.tsv > $DIR/source2 &

# connect up the output

cat $DIR/output > /Users/jmay/Projects/Numbrary/DataSources/ca/schools/output.tsv &

echo "RUNNING THE PIPELINE"

# run the pipeline from named pipes to named pipe

cat $DIR/source1 | tools/filter2 --filter $DIR/source2 --column 0 --fcol 0 > $DIR/output

echo "CLEANING UP"

# delete the working directory and all its contents
$RM -rf $DIR

echo "DONE"
