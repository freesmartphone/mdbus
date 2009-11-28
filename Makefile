SUBDIRS = \
	libfsobasics \
	libfsotransport \
	libfsoresource \
	libfsoframework \
	fsodatad \
	fsodeviced \
	fsogsmd \
	fsolocationd \
	fsonetworkd \
	fsomusicd \
	fsousaged \
	fsotimed

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
    
