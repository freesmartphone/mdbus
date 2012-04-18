#!/bin/sh
ROOT=`pwd`
. ./scripts/list_components.sh
for comp in $COMPONENTS; do
	pushd $comp
	$ROOT/scripts/gitlog-to-changelog . > ChangeLog
	popd
done

