include $(top_srcdir)/Makefile.decl

NULL=

THISDIR = `basename $$PWD`

confdir = $(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsoaudiod.conf \
	$(NULL)

# boards compatible with palm_pre
COMPAT = \
	SirloinOMAP3430board \
	SirloinOMAP3640board \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(sysconfdir)/freesmartphone/conf/$$compat; done


MAINTAINERCLEANFILES = Makefile.in
