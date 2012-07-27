#!/bin/sh
find . -name configure.ac | xargs sed -i -e "s:_base_version\], \[$1:_base_version\], \[$2:g"

