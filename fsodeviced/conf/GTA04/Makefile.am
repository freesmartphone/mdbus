include $(top_srcdir)/Makefile.decl

NULL=

SUBDIRS = alsa-3.2

THISDIR = `basename $$PWD`

confdir = $(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	alsa.conf \
	$(NULL)

# boards compatible with this machine
COMPAT = \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/etc/freesmartphone/conf/
	ln -sf alsa-3.2 $(DESTDIR)/etc/freesmartphone/conf/$(THISDIR)/alsa-default
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(DESTDIR)/etc/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
