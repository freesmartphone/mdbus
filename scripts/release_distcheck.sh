#!/bin/sh

. ./scripts/list_components.sh

for comp in $COMPONENTS; do
	pushd $comp
	if [ ! -f ".skip_distcheck" ] ; then
		if [ -f "Makefile" ] ; then
			sudo make maintainer-clean
		fi

		./autogen.sh

		if [ $comp == "fsogsmd" ] ; then
			./configure --enable-libgsm0710mux --enable-modem-qualcomm-palm \
				--enable-modem-nokia-isi --enable-modem-samsung
		elif [ $comp == "fsodeviced" ] ; then
			./configure --enable-kernel26-rfkill --enable-player-canberra \
				--enable-player-gstreamer
		elif [ $comp == "fsoaudiod" ] ; then
			./configure --enable-cmtspeechdata --enable-samplerate
		elif [ $comp == "fsotdld" ] ; then
			./configure --enable-provider-libgps
		fi

		make || exit 1
		sudo make distcheck || exit 1
		touch .skip_distcheck
	fi
	popd
done
