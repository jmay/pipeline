#!/usr/bin/env bash
#
# unzip can't read from STDIN, so needed another way for it to find the source file.
#
# pipeline.pl is recoding the path to the original source file in $INPUT0 in the environment,
# trusting that the modules will all behave themselves.  I hope this never breaks anything.
# So unzip can look at the original file.
# At least with -p it can send output to stdout; we trust that any zip input will contain just
# a single file, or it multiple then any bits we don't want will get zapped later in the pipeline.
#

unzip -p $INPUT0
