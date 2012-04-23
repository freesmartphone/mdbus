#!/bin/sh

. ./scripts/list_components.sh

for comp in $COMPONENTS; do
	pushd $comp
	if [ ! -f ".skip_distcheck" ] ; then
		if [ -f "Makefile" ] ; then
			sudo make maintainer-clean
		fi

		NOCONFIGURE=1 ./autogen.sh

		CFLAGS=""

		if [ $comp == "fsogsmd" ] ; then
			CFLAGS="--enable-libgsm0710mux --enable-modem-qualcomm-palm --enable-modem-nokia-isi --enable-modem-samsung"
		elif [ $comp == "fsodeviced" ] ; then
			CFLAGS="--enable-kernel26-rfkill --enable-player-canberra --enable-player-gstreamer"
		elif [ $comp == "fsoaudiod" ] ; then
			CFLAGS="--enable-cmtspeechdata --enable-samplerate"
		elif [ $comp == "fsotdld" ] ; then
			CFLAGS="--enable-provider-libgps"
		fi

		./configure --enable-vala $CFLAGS

		make || exit 1
		sudo make distcheck || exit 1
		touch .skip_distcheck
	fi
	popd
done
