#!/bin/sh

. ./scripts/list_components.sh

for comp in $COMPONENTS; do
	pushd $comp
	if [ ! -f ".skip_distcheck" ] ; then
		if [ -f "Makefile" ] ; then
			sudo make distclean
		fi
		./autogen.sh
		make distcheck || exit 1
	fi
	popd
done
