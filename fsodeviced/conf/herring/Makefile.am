include $(top_srcdir)/Makefile.decl

NULL=
SUBDIRS = alsa-default

confdir = $(sysconfdir)/freesmartphone/conf/herring
dist_conf_DATA = \
	fsodeviced.conf \
	alsa.conf \
	$(NULL)

# boards compatible with herring
COMPAT = \
	crespo \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./herring $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
