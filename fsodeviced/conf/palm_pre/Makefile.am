include $(top_srcdir)/Makefile.decl

NULL=

# SUBDIRS = alsa-default

THISDIR = `basename $$PWD`

confdir = $(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with palm_pre
COMPAT = \
	SirloinOMAP3430board \
	SirloinOMAP3630board \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/etc/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(DESTDIR)/etc/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
