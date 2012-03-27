include $(top_srcdir)/Makefile.decl

NULL=

# SUBDIRS = alsa-default

confdir = $(sysconfdir)/freesmartphone/conf/htcleo
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/etc/freesmartphone/conf/

MAINTAINERCLEANFILES = Makefile.in
