SUBDIRS = \
	libfsobasics \
	libfsotransport \
	libfsoframework \
	libgsm0710mux \
	libfsoresource \
	libfsosystem \
	fsoaudiod \
	fsodatad \
	fsodeviced \
	fsogsmd \
	fsonetworkd \
	fsophoned \
	fsousaged \
	fsotdld

SUDO = sudo

all:
	for i in $(SUBDIRS); do $(MAKE) -C $$i; done

install:
	for i in $(SUBDIRS); do $(SUDO) $(MAKE) install -C $$i; done

clean:
	for i in $(SUBDIRS); do $(MAKE) clean -C $$i; done

test:
	for i in $(SUBDIRS); do $(MAKE) test -C $$i; done

maintainer-clean:
	for i in $(SUBDIRS); do $(MAKE) maintainer-clean -C $$i; done

rebuild:
	pushd libfsobasics; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd libfsotransport; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd libgsm0710mux; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd libfsoframework; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd libfsosystem; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd libfsoresource; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd fsoaudiod; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd fsodatad; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd fsodeviced; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd fsogsmd; $(SUDO) make uninstall; ./autogen.sh --enable-modem-qualcomm-palm --enable-libgsm0710mux; $(SUDO) make install; popd
	pushd fsonetworkd; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd fsophoned; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd fsousaged; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
	pushd fsotdld; $(SUDO) make uninstall; ./autogen.sh; $(SUDO) make install; popd
