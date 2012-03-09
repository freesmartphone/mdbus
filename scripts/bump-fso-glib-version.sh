#!/bin/sh
find . -name configure.ac | xargs sed -i -e s:^FSO_GLIB_REQUIRED=.*$:FSO_GLIB_REQUIRED=$1:g
