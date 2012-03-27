include $(top_srcdir)/Makefile.decl

NULL=

SUBDIRS = alsa-default

confdir = $(sysconfdir)/freesmartphone/conf/nokia_n900
dist_conf_DATA = \
	fsodeviced.conf \
	alsa.conf \
	$(NULL)

# boards compatible with this machine
COMPAT = \
	NokiaRX-51board \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./nokia_n900 $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
