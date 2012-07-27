#!/bin/sh
find . -name configure.ac | xargs sed -i -e "s:_released\], \[0\]:_released\], \[1\]:g"

