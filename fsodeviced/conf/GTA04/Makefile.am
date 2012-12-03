include $(top_srcdir)/Makefile.decl

NULL=

SUBDIRS = alsa-3.4 swrouting

confdir = $(sysconfdir)/freesmartphone/conf/GTA04
dist_conf_DATA = \
	fsodeviced.conf \
	alsa.conf \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	ln -sf alsa-3.4 $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/GTA04/alsa-default
	ln -sf alsa-3.4 alsa-3.2
	ln -sf alsa-3.4 alsa-3.5

MAINTAINERCLEANFILES = Makefile.in
