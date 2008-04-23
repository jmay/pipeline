#!/bin/bash

############################################################
#
# acquire_source.sh
#
# DESCRIPTION:
#
# Download a file from a given URI and inject it into a particular
# Numbrary source as the 'raw' component.
#
#
# USAGE:
#
#  acquire_source.sh [source-name] [uri] [rootdir]
#
############################################################

SOURCE=$1
URI=$2
ROOT=$3

DOWNLOADED=`mktemp -t numbrary.XXXX`

curl --silent $URI > $DOWNLOADED
if [ $? == 0 ]
then
  ID=`$TOOLS/move_into_filetree.pl --root $ROOT --filename $DOWNLOADED`
  $TOOLS/inject_file.rb --source $SOURCE --component raw --storage datatree --file $ID
else
  echo "unable to download $URI" >&2
fi

/bin/rm $DOWNLOADED

exit 0
