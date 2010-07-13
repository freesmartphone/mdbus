include $(top_srcdir)/Makefile.decl

NULL=

SUBDIRS = \
	alsa-2.6.29 \
	alsa-2.6.31 \
	$(NULL)

THISDIR = `basename $$PWD`

confdir = $(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	alsa.conf \
	$(NULL)

# boards compatible with openmoko_gta
COMPAT = \
	GTA01 \
	GTA02 \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/etc/freesmartphone/conf/
	ln -sf alsa-2.6.31 $(DESTDIR)/etc/freesmartphone/conf/$(THISDIR)/alsa-default
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(DESTDIR)/etc/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
