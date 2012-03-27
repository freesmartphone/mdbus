include $(top_srcdir)/Makefile.decl

NULL=

SUBDIRS = \
	alsa-2.6.29 \
	alsa-2.6.31 \
	alsa-2.6.34 \
	alsa-2.6.39 \
	$(NULL)

confdir = $(sysconfdir)/freesmartphone/conf/openmoko_gta
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
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	ln -sf alsa-2.6.39 $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/openmoko_gta/alsa-default
	for compat in $(COMPAT); do ln -sf ./openmoko_gta $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
