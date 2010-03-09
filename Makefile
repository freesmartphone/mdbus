SUBDIRS = \
	libfsobasics \
	libfsotransport \
	libfsoresource \
	libfsoframework \
	fsodatad \
	fsodeviced \
	fsogsmd \
	fsonetworkd \
	fsomusicd \
	fsousaged \
	fsotdld

all:
	for i in $(SUBDIRS); do $(MAKE) -C $$i; done

install:
	for i in $(SUBDIRS); do $(MAKE) install -C $$i; done

clean:
	for i in $(SUBDIRS); do $(MAKE) clean -C $$i; done

test:
	for i in $(SUBDIRS); do $(MAKE) test -C $$i; done

maintainer-clean:
	for i in $(SUBDIRS); do $(MAKE) maintainer-clean -C $$i; done

rebuild:
	pushd libfsobasics; make uninstall; ./autogen.sh; make install; popd
	pushd libfsotransport; make uninstall; ./autogen.sh; make install; popd
	pushd libgsm0710mux; make uninstall; ./autogen.sh; make install; popd
	pushd libresource; make uninstall; ./autogen.sh; make install; popd
	pushd libfsoframework; make uninstall; ./autogen.sh; make install; popd
	pushd fsodatad; make uninstall; ./autogen.sh; make install; popd
	pushd fsodeviced; make uninstall; ./autogen.sh; make install; popd
	pushd fsogsmd; make uninstall; ./autogen.sh --enable-modem-qualcomm-palm --enable-libgsm0710mux; make install; popd
	pushd fsonetworkd; make uninstall; ./autogen.sh; make install; popd
	pushd fsousaged; make uninstall; ./autogen.sh; make install; popd
	#pushd fsotdld; make uninstall; ./autogen.sh; make install; popd
