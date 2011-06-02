#!/bin/sh
find . -name configure.ac | xargs sed -i -e s:^VALA_REQUIRED=.*$:VALA_REQUIRED=$1:g
