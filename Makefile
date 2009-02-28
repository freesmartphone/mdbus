SUBDIRS = libfsoframework odeviced

all:
	for i in $(SUBDIRS); do $(MAKE) -C $$i; done
	
install:
	for i in $(SUBDIRS); do $(MAKE) install -C $$i; done

clean:
	for i in $(SUBDIRS); do $(MAKE) clean -C $$i; done
