#!/bin/sh
find . -name configure.ac | xargs grep "base_version\], \[0."
