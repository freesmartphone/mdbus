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
	for i in $(SUBDIRS); do pushd $$i && ./autogen.sh && make clean && make && make install && popd; done
