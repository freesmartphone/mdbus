SUBDIRS = \
	libfsobasics \
	libfsotransport \
	libfsoresource \
	libfsoframework \
	fsodeviced \
	fsousaged \
	fsotimed \
	fsogpsd \
	fsogsmd \
	fsonetworkd

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
    
