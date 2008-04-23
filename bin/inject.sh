#!/bin/bash

SOURCE=$1
COMPONENT=$2
FILE=$3

MODULE_PATH="`dirname $0`/../mod"

# Inject a file into a source as a named component

echo "$MODULE_PATH/move_into_filetree.pl --root $RAILS_ROOT/data --filename $FILE" >&2
FILEID=`$MODULE_PATH/move_into_filetree.pl --root $RAILS_ROOT/data --filename $FILE`
if [ -z "$FILEID" ]
then
  echo "Aborting"
  exit 1
fi

echo "$MODULE_PATH/inject_file.rb --source $SOURCE --component $2 --storage datatree --filename $FILEID" >&2

$MODULE_PATH/inject_file.rb --source $SOURCE --component $2 --storage datatree --filename $FILEID
