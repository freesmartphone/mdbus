include $(top_srcdir)/Makefile.decl

NULL=

# SUBDIRS = alsa-default

confdir = $(sysconfdir)/freesmartphone/conf/palm_pre
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with palm_pre
COMPAT = \
	SirloinOMAP3430board \
	SirloinOMAP3630board \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./palm_pre $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
